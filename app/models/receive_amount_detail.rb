# frozen_string_literal: true
# == Schema Information
#
# Table name: receive_amount_details
#
#  id                        :bigint(8)        not null, primary key
#  receive_amount_history_id :bigint(8)        not null
#  order_number              :string(255)
#  dealer_name               :string(50)
#  dealer_type               :integer
#  tax_id                    :string(15)
#  th_company_name           :string(255)
#  en_company_name           :string(255)
#  bill_date                 :string(15)
#  site_code                 :string(15)
#  site_name                 :string(255)
#  product_name              :string(40)
#  installment_number        :integer
#  due_ymd                   :string(8)
#  input_ymd                 :string(8)
#  switched_date             :datetime
#  rescheduled_date          :datetime
#  repayment_ymd             :string(8)
#  principal                 :decimal(10, 2)
#  interest                  :decimal(10, 2)
#  late_charge               :decimal(10, 2)
#  paid_principal            :decimal(10, 2)
#  paid_interest             :decimal(10, 2)
#  paid_late_charge          :decimal(10, 2)
#  total_principal           :decimal(10, 2)
#  total_interest            :decimal(10, 2)
#  total_late_charge         :decimal(10, 2)
#  exceeded_occurred_amount  :decimal(10, 2)
#  exceeded_occurred_ymd     :string(8)
#  exceeded_paid_amount      :decimal(10, 2)
#  cashback_paid_amount      :decimal(10, 2)
#  cashback_occurred_amount  :decimal(10, 2)
#  waive_late_charge         :decimal(10, 2)
#  contractor_id             :bigint(8)        not null
#  payment_id                :bigint(8)
#  order_id                  :bigint(8)
#  installment_id            :bigint(8)
#  dealer_id                 :bigint(8)
#  deleted                   :integer          default(0), not null
#  created_at                :datetime
#  updated_at                :datetime
#  operation_updated_at      :datetime
#

class ReceiveAmountDetail < ApplicationRecord
  # デフォルトスコープはつけない
  # default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :receive_amount_history
  belongs_to :payment, optional: true
  belongs_to :order, optional: true
  belongs_to :installment, optional: true
  belongs_to :dealer, optional: true

  validates :receive_amount_history_id,
            uniqueness: {
              scope: [:contractor_id, :installment_id],
              conditions: -> { where(deleted: 0) },
              case_sensitive: false
            }

  def dealer_type_label
    # application_record に定義した localeを使用する
    enum_to_label('dealer_type', class_name: 'application_record')
  end
end
