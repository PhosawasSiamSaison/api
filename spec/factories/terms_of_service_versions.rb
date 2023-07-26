# frozen_string_literal: true
# == Schema Information
#
# Table name: terms_of_service_versions
#
#  id                   :bigint(8)        not null, primary key
#  contractor_user_id   :bigint(8)
#  dealer_type          :integer
#  sub_dealer           :boolean          default(FALSE), not null
#  integrated           :boolean          default(FALSE), not null
#  individual           :boolean          default(FALSE), not null
#  version              :integer          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :terms_of_service_version do
    trait :cbm do
      dealer_type { :cbm }
    end

    trait :cpac do
      dealer_type { :cpac }
    end

    trait :sub_dealer do
      dealer_type { nil }
      sub_dealer { true }
    end

    trait :permsin do
      dealer_type { :permsin }
    end

    trait :integrated do
      dealer_type { nil }
      integrated { true }
    end

    association :contractor_user
    dealer_type { :cbm }
    sub_dealer { false }
    integrated { false }
    version { 1 }
  end
end
