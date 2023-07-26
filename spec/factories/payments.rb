# frozen_string_literal: true
# == Schema Information
#
# Table name: payments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :integer          not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  paid_up_operated_ymd :string(8)
#  total_amount         :decimal(10, 2)   default(0.0), not null
#  paid_total_amount    :decimal(10, 2)   default(0.0), not null
#  paid_exceeded        :decimal(10, 2)   default(0.0), not null
#  paid_cashback        :decimal(10, 2)   default(0.0), not null
#  status               :integer          default("not_due_yet"), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  trait :not_due_yet do
    status { 'not_due_yet' }
  end

  trait :next_due do
    status { 'next_due' }
  end

  trait :paid do
    paid_up_ymd { '20190101' }
    status { 'paid' }
  end

  trait :over_due do
    status { 'over_due' }
  end

  factory :payment do
    association :contractor
    due_ymd { '20190228' }
    total_amount { 1000000.0 }
    status { 'not_due_yet' }
  end
end
