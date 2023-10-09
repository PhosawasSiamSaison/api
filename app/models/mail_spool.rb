# == Schema Information
#
# Table name: mail_spools
#
#  id                         :bigint(8)        not null, primary key
#  contractor_id              :bigint(8)
#  subject                    :string(255)
#  mail_body                  :text(65535)
#  mail_type                  :integer          not null
#  contractor_billing_data_id :bigint(8)
#  send_status                :integer          default("unsent"), not null
#  deleted                    :integer          default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  operation_updated_at       :datetime
#

class MailSpool < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor, optional: true
  belongs_to :contractor_billing_data, optional: true
  # belongs_to :contractor_billing_datum, class_name: :ContractorBillingData, optional: true
  has_many :send_email_addresses
  has_many :contractor_users, through: :send_email_addresses

  enum mail_type: {
    online_apply_one_time_passcode_mail: 1,
    approve_contractor:                  2,
    reject_contractor:                   3,
    scoring_results_to_staff:            4,
    pdpa_agree:                          5,
    pdpa_results_to_staff:               6,
    online_apply_complete:               7,
    contractor_billing_pdf:              8,
    receive_payment:                     9,
    exceeded_payment:                   10,
    test_mail:                          99,
    # 追加したら mask_mail_body を更新する!
  }

  validates :mail_type, presence: true
  validates :send_status, presence: true

  class << self
    def search(params)
      relation = all.joins(:send_email_addresses).eager_load(:contractor, :contractor_users)
        .where(send_status: :done)
        .where("mail_spools.updated_at > ?", (BusinessDay.today - 3.days).strftime("%Y-%m-%d %H:%M:%S"))
        .order(updated_at: :DESC, id: :DESC)

      # Email Address
      if params.dig(:search, :email_address).present?
        email_address = params.dig(:search, :email_address)
        relation  = relation.where('send_email_addresses.send_to LIKE ?', "%#{email_address}%")
      end

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # User Name
      if params.dig(:search, :user_name).present?
        user_name = params.dig(:search, :user_name)
        relation = relation.where("contractor_users.user_name LIKE ?", "%#{user_name}%")
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    def create_and_send_mail(
      subject, mail_body, mail_type,
      contractor: nil, contractor_user: nil, contractor_users: [], email: nil, contractor_billing_data: nil)

      # 作成
      create_mail(contractor, contractor_user, contractor_users, subject, mail_body, mail_type, email, contractor_billing_data)

      # 送信
      send_mail(mail_type)
    end

    private
      def create_mail(contractor, contractor_user, contractor_users, subject, mail_body, mail_type, email, contractor_billing_data)
        send_to = contractor_user&.email || email

        if Rails.env.development?
          # 誤送信を防ぐ
          send_to = JvService::Application.config.try(:mask_mail_address) || ''
        end

        mail_spool = create!(
          contractor: contractor || contractor_user&.contractor,
          send_status: :unsent,
          subject: subject,
          mail_body: mail_body.to_s,
          mail_type: mail_type,
          contractor_billing_data: contractor_billing_data,
          # contractor_billing_datum_id: contractor_billing_data.id,
          # contractor_billing_datum: contractor_billing_data,
        )

        # ปลายทางเดียว
        if send_to.present?
          mail_spool.send_email_addresses.create!(contractor_user: contractor_user, send_to: send_to)

        # ปลายทางหลายแห่ง
        else
          # ยกเว้นปลายทางที่ซ้ำกัน
          uniq_contractor_users = contractor_users.uniq{|contractor_user| contractor_user.email}

          uniq_contractor_users.each do |contractor_user|
            send_to = contractor_user&.email

            if Rails.env.development?
              # 誤送信を防ぐ
              send_to = JvService::Application.config.try(:mask_mail_address) || ''
            end

            pp "::: must use send_to = #{send_to}"
            mail_spool.send_email_addresses.create!(contractor_user: contractor_user, send_to: send_to)
          end
        end
      end

      def send_mail(mail_type)
        unsent_mail_objects = []

        transaction do
          unsent_mail_objects = lock.where(send_status: :unsent, mail_type: mail_type).order(:id)

          return if unsent_mail_objects.blank?

          unsent_mail_objects.update_all(send_status: :sending)
        end

        # 送信フラグがオフの場合は送信しない

        return unless JvService::Application.config.try(:send_mail)

        unsent_mail_objects.each {|mail|
          JvMailer.with(mail_spool: mail).send_mail.deliver_later
        }
      end
  end

  def email_addresses_str
    send_email_addresses.map(&:send_to).join(', ')
  end

  def sender
    if pdpa_agree?
      # PDPA
      from_name    = JvService::Application.config.try(:mail_sender_name_pdpa)
      from_address = JvService::Application.config.try(:mail_sender_address_pdpa)
    else
      # 標準
      from_name    = JvService::Application.config.try(:mail_sender_name)
      from_address = JvService::Application.config.try(:mail_sender_address)
    end

    "#{from_name} <#{from_address}>"
  end

  def delivery_method_options
    if pdpa_agree?
      # PDPA
      {
        user_name: JvService::Application.config.try(:smtp_user_name_pdpa),
        password:  JvService::Application.config.try(:smtp_password_pdpa),
      }
    else
      # 標準
      {
        user_name: JvService::Application.config.try(:smtp_user_name),
        password:  JvService::Application.config.try(:smtp_password),
      }
    end
  end

  def mail_type_label
    enum_to_label('mail_type')
  end

  def send_status_label
    enum_to_label('send_status', class_name: 'application_record')
  end

  def mask_mail_body
    # パスコードのあるメッセージをマスキングする

    # 表示を許可する mail_type(追記漏れを防ぐためにホワイトリストで記述)
    [
      :approve_contractor,
      :reject_contractor,
      :scoring_results_to_staff,
      :pdpa_agree,
      :pdpa_notification_to_ss_staffs,
      :online_apply_complete,
      :contractor_billing_pdf,
      :receive_payment,
      :exceeded_payment,
    ].include?(mail_type.to_sym) ? mail_body : 'Cannot show because it is OTP mail.'
  end
end
