# == Schema Information
#
# Table name: applied_dealers
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  dealer_id            :bigint(8)        not null
#  sort_number          :integer          not null
#  applied_ymd          :string(8)        not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :applied_dealer do
    association :contractor
    association :dealer
    sort_number { 1 }
    applied_ymd { "20200101" }
  end
end