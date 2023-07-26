# frozen_string_literal: true
# == Schema Information
#
# Table name: sites
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  dealer_id            :bigint(8)        not null
#  is_project           :boolean          default(FALSE), not null
#  site_code            :string(15)       not null
#  site_name            :string(255)      not null
#  site_credit_limit    :decimal(13, 2)   not null
#  closed               :boolean          default(FALSE), not null
#  create_user_id       :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class Site < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :create_user, class_name: :ContractorUser, unscoped: true
  belongs_to :dealer
  has_many :orders
  has_many :dealers, through: :orders

  validates :site_code,
            length: { maximum: 15 }

  validates :site_name,
            length: { maximum: 255 }

  scope :not_close, -> { where(closed: false) }
  scope :not_projects, -> { where(is_project: false) }
  scope :is_projects, -> { where(is_project: true) }

  class << self
    def search(params)
      relation = includes(:dealer).where(contractor_id: params[:contractor_id])
      .order(created_at: :DESC, id: :DESC)

      if params.dig(:search, :include_closed).to_s != 'true'
        relation = relation.not_close
      end

      # Paging
      if params[:page].present? && params[:per_page].present?
        result = paginate(params[:page], relation, params[:per_page])
      else
        result = relation
      end

      [result, relation.count]
    end
  end

  def closed?
    closed
  end

  def open?
    !closed
  end

  # Used Amount
  def remaining_principal
    orders.payable_orders.sum(&:remaining_principal).round(2).to_f
  end

  def available_balance
    amount = (site_credit_limit - remaining_principal).round(2).to_f

    # マイナスは0にする
    [amount, 0.0].max
  end

  def over_site_credit_limit?(amount, current_amount)
    # VAT?の分の枠を広げる
    expanded_credit_limit_amount =
      BigDecimal(site_credit_limit.to_s) * SystemSetting.credit_limit_additional_rate

    # 利用可能限度枠から残りの返済額を引く(マイナスは0にする)
    available_balance =
      [(expanded_credit_limit_amount - (remaining_principal - current_amount)).round(2), 0].max

    available_balance < amount
  end

  def too_long?(column)
    valid?
    errors.details[column.to_sym].any?{|col| col[:error] == :too_long}
  end
end
