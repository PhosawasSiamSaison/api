# frozen_string_literal: true
# == Schema Information
#
# Table name: dealer_type_limits
#
#  id                   :bigint(8)        not null, primary key
#  eligibility_id       :bigint(8)
#  dealer_type          :integer          default("cbm"), not null
#  limit_amount         :decimal(13, 2)   not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :dealer_type_limit do
    trait :cbm do
      dealer_type { :cbm }
    end

    trait :cpac do
      dealer_type { :cpac }
    end

    trait :q_mix do
      dealer_type { :q_mix }
    end

    trait :b2b do
      dealer_type { :b2b }
    end

    trait :permsin do
      dealer_type { :permsin }
    end

    association :eligibility
    dealer_type { :cbm }
    limit_amount { 99999999999.0 }
  end
end
