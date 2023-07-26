# frozen_string_literal: true
# == Schema Information
#
# Table name: receive_amount_histories
#
#  id                    :bigint(8)        not null, primary key
#  contractor_id         :integer          not null
#  receive_ymd           :string(8)        not null
#  receive_amount        :decimal(10, 2)   not null
#  exemption_late_charge :decimal(10, 2)
#  comment               :text(65535)      not null
#  repayment_id          :string(32)
#  create_user_id        :integer
#  deleted               :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  operation_updated_at  :datetime
#  lock_version          :integer          default(0)
#

class ReceiveAmountHistory < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :create_user, class_name: :JvUser, unscoped: true, optional: true
  has_many :receive_amount_details, -> {where(deleted: false)}

  validates :receive_ymd, presence: true, length: { is: 8 }

  class << self
    def search(params)
      relation = all.eager_load(:contractor, :create_user).order(created_at: :DESC, id: :DESC)

      # Date (receive_ymd)
      if params.dig(:search, :receive_ymd).present?
        receive_ymd = params.dig(:search, :receive_ymd)
        relation = relation.where(receive_ymd: receive_ymd)
      end

      # TAX ID(tax_id)
      if params.dig(:search, :tax_id).present?
        tax_id   = params.dig(:search, :tax_id)
        relation = relation.where("contractors.tax_id LIKE ?", "#{tax_id}%")
      end

      # Company Name
      if params.dig(:search, :company_name).present?
        company_name = params.dig(:search, :company_name)
        relation     = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
      end

      # ページング前のtotal_amount
      total_amount = relation.inject(0.0) do |sum, history|
        (sum + history.receive_amount).round(2).to_f
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, total_amount, relation.count]
    end

    def paging(params)
      result = paginate(params[:page], all, params[:per_page])

      [result, all.count]
    end
  end

  # 発生したexceededをdetailsから取得
  def exceeded_occurred_amount
    receive_amount_details.last.exceeded_occurred_amount
  end
end
