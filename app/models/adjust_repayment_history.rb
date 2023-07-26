# frozen_string_literal: true

# == Schema Information
#
# Table name: adjust_repayment_histories
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  installment_id       :bigint(8)        not null
#  created_user_id      :bigint(8)
#  business_ymd         :string(8)        not null
#  to_exceeded_amount   :decimal(10, 2)   not null
#  before_detail_json   :text(65535)
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#


class AdjustRepaymentHistory < ApplicationRecord
  belongs_to :contractor
  belongs_to :installment
  belongs_to :created_user, class_name: 'JvUser', optional: true, unscoped: true

  def insert_association
    self.contractor = installment.order.contractor
    self.business_ymd = BusinessDay.today_ymd
    self.to_exceeded_amount = installment.paid_total_amount

    payment = installment.payment
    self.before_detail_json = {
      pool_amount: contractor.pool_amount.to_f,
      payment: {
        paid_exceeded:     payment.paid_exceeded.to_f,
        paid_cashback:     payment.paid_cashback.to_f,
        paid_total_amount: payment.paid_total_amount.to_f,
      },
      installment: {
        paid_principal:   installment.paid_principal.to_f,
        paid_interest:    installment.paid_interest.to_f,
        paid_late_charge: installment.paid_late_charge.to_f,
        used_exceeded:    installment.used_exceeded.to_f,
        used_cashback:    installment.used_cashback.to_f,
      }
    }.to_json
  end
end
