# == Schema Information
#
# Table name: line_spools
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  contractor_user_id   :bigint(8)        not null
#  send_to              :string(255)      not null
#  message_body         :text(65535)
#  message_type         :integer          not null
#  send_status          :integer          default("unsent"), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#

class LineSpool < ApplicationRecord
  include MessageModule

  default_scope { where(deleted: 0) }

  # deletedのContractorUserを検索できる様にするjoin
  scope :join_unscoped_contractor_users, -> {
    joins('INNER JOIN contractor_users ON contractor_users.id = line_spools.contractor_user_id')
  }

  belongs_to :contractor, optional: true
  belongs_to :contractor_user, unscoped: true, optional: true

  validates :message_type, presence: true
  validates :send_status, presence: true

  class << self
    def search(params)
      relation = all.eager_load(:contractor)
        .join_unscoped_contractor_users
        .where(send_status: [:done, :failed])
        .where("line_spools.updated_at > ?", (BusinessDay.today - 3.days).strftime("%Y-%m-%d %H:%M:%S"))
        .order(updated_at: :DESC, id: :DESC)

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # User Name
      if params.dig(:search, :user_name).present?
        user_name = params.dig(:search, :user_name)
        relation  = relation.where("contractor_users.user_name LIKE ?", "%#{user_name}%")
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end

    def create_and_send_line(contractor_user, message_body, message_type)
      # 作成
      create_line(contractor_user, message_body, message_type)

      # 送信
      send_line(message_type)
    end

    private
      def create_line(contractor_user, message_body, message_type)
        send_to = contractor_user.line_user_id

        if Rails.env.development?
          # 誤送信を防ぐ
          send_to = JvService::Application.config.try(:mask_line_user_id) || ''
        end

        create!(
          contractor: contractor_user.contractor,
          contractor_user: contractor_user,
          send_status: :unsent,
          send_to: send_to,
          message_body: message_body.to_s,
          message_type: message_type
        )
      end

      def send_line(message_type)
        unsent_line_objects = []

        transaction do
          unsent_line_objects = lock.where(send_status: :unsent, message_type: message_type).order(:id)

          return if unsent_line_objects.blank?

          unsent_line_objects.update_all(send_status: :sending)
        end

        # 送信フラグがオフの場合は送信しない
        return unless JvService::Application.config.try(:send_line)

        unsent_line_objects.each {|line|
          SendLineJob.perform_later(line)
        }
      end
  end

  def message_type_label
    enum_to_label('message_type', class_name: 'application_record')
  end

  def send_status_label
    enum_to_label('send_status', class_name: 'application_record')
  end
end
