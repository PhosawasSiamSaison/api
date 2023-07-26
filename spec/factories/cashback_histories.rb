# == Schema Information
#
# Table name: cashback_histories
#
#  id                        :bigint(8)        not null, primary key
#  contractor_id             :integer          not null
#  point_type                :integer          not null
#  cashback_amount           :decimal(10, 2)   not null
#  latest                    :boolean          not null
#  total                     :decimal(10, 2)   not null
#  exec_ymd                  :string(8)        not null
#  notes                     :string(100)
#  order_id                  :integer
#  receive_amount_history_id :bigint(8)
#  deleted                   :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  operation_updated_at      :datetime
#  lock_version              :integer          default(0)
#

FactoryBot.define do
  trait :gain do
    point_type { 'gain' }
  end

  trait :use do
    point_type { 'use' }
  end

  trait :latest do
    latest { true }
  end

  factory :cashback_history do
    contractor { order.contractor }
    point_type { 'gain' }
    cashback_amount { 100 }
    latest { false }
    total { cashback_amount }
    exec_ymd { '20190130' }
  end
end
