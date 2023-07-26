# == Schema Information
#
# Table name: sms_spools
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  contractor_user_id   :integer
#  send_to              :string(255)      not null
#  message_body         :text(65535)
#  message_type         :integer          not null
#  send_status          :integer          default("unsent"), not null
#  sms_provider         :integer
#  deleted              :integer          default(0), not null
#  lock_version         :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#

class SmsSpool < ApplicationRecord
  include MessageModule

  default_scope { where(deleted: 0) }

  # deletedのContractorUserを検索できる様にするjoin
  scope :join_unscoped_contractor_users, -> {
    joins('LEFT OUTER JOIN contractor_users ON contractor_users.id = sms_spools.contractor_user_id')
  }

  belongs_to :contractor, optional: true
  belongs_to :contractor_user, unscoped: true, optional: true

  enum sms_provider: { thai_bulk_sms: 1, aws_sns: 2 }

  validates :message_type, presence: true
  validates :send_status, presence: true

  class << self
    def search(params)
      relation = all.eager_load(:contractor)
        .join_unscoped_contractor_users
        .where(send_status: :done)
        .where("sms_spools.updated_at > ?", (BusinessDay.today - 3.days).strftime("%Y-%m-%d %H:%M:%S"))
        .order(updated_at: :DESC, id: :DESC)

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation     = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # User Name
      if params.dig(:search, :user_name).present?
        user_name = params.dig(:search, :user_name)
        relation  = relation.where("contractor_users.user_name LIKE ?", "%#{user_name}%")
      end

      # Mobile Number
      if params.dig(:search, :mobile_number).present?
        mobile_number = params.dig(:search, :mobile_number)
        relation  = relation.where(send_to: mobile_number)
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    def create_and_send_sms(contractor_user, message_body, message_type, mobile_number)
      # 作成
      create_sms(contractor_user, message_body, message_type, mobile_number)

      # 送信
      send_sms(message_type)
    end

    private
      def create_sms(contractor_user, message_body, message_type, mobile_number)
        send_to = contractor_user&.mobile_number || mobile_number

        if Rails.env.development?
          # 誤送信を防ぐために環境変数で設定する携帯番号に変える
          send_to = JvService::Application.config.try(:mask_mobile_number) || ''
        end

        create!(
          contractor: contractor_user&.contractor,
          contractor_user: contractor_user,
          send_status: :unsent,
          send_to: send_to,
          message_body: message_body.to_s,
          message_type: message_type
        )
      end

      def send_sms(message_type)
        unsent_sms_objects = []

        transaction do
          unsent_sms_objects = lock.where(send_status: :unsent, message_type: message_type).order(:id)

          return if unsent_sms_objects.blank?

          unsent_sms_objects.update_all(send_status: :sending)
        end

        # 送信フラグがオフの場合は送信しない
        return unless JvService::Application.config.try(:send_sms)

        # 検証環境で送信しない電話番号
        not_send_mobile_numbers = JvService::Application.config.try(:not_send_mobile_numbers) || []

        unsent_sms_objects.each { |sms|
          next if not_send_mobile_numbers.include?(sms.send_to)

          SendSmsJob.perform_later(sms)
        }
      end
  end

  def message_type_label
    enum_to_label('message_type', class_name: 'application_record')
  end
end
