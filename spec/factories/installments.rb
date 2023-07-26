# == Schema Information
#
# Table name: installments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  order_id             :integer          not null
#  payment_id           :integer
#  installment_number   :integer          not null
#  rescheduled          :boolean          default(FALSE), not null
#  exempt_late_charge   :boolean          default(FALSE), not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  principal            :decimal(10, 2)   default(0.0), not null
#  interest             :decimal(10, 2)   default(0.0), not null
#  paid_principal       :decimal(10, 2)   default(0.0), not null
#  paid_interest        :decimal(10, 2)   default(0.0), not null
#  paid_late_charge     :decimal(10, 2)   default(0.0), not null
#  used_exceeded        :decimal(10, 2)   default(0.0)
#  used_cashback        :decimal(10, 2)   default(0.0)
#  reduced_site_limit   :decimal(10, 2)   default(0.0)
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :installment do
    trait :paid_up do
      paid_up_ymd { '20190101' }
    end

    trait :deleted do
      deleted { true }
    end

    association :order
    contractor { order.contractor }
    installment_number { 1 }
    due_ymd { payment&.due_ymd || '20190101'}
    paid_up_ymd { payment&.paid_up_ymd }
    principal { 1000000.0 }
  end
end
