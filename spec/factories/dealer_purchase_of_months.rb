# == Schema Information
#
# Table name: dealer_purchase_of_months
#
#  id                   :bigint(8)        not null, primary key
#  dealer_id            :bigint(8)
#  month                :string(6)
#  purchase_amount      :decimal(10, 2)   default(0.0), not null
#  order_count          :integer          default(0), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :dealer_purchase_of_month do
    association :dealer
    purchase_amount { 1000.0 }
    month { "201901" }
    order_count { 1 }
  end
end
