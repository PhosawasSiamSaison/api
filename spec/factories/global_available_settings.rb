# == Schema Information
#
# Table name: global_available_settings
#
#  id                   :bigint(8)        not null, primary key
#  contractor_type      :integer          not null
#  category             :integer          not null
#  dealer_type          :integer          not null
#  product_id           :bigint(8)        not null
#  available            :boolean          not null
#  create_user_id       :bigint(8)
#  update_user_id       :bigint(8)
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

FactoryBot.define do
  factory :global_available_setting do
    trait :cbm do
      dealer_type { :cbm }
    end

    trait :gh do
      dealer_type { :global_house }
    end

    trait :purchase do
      category { :purchase }
    end

    trait :switch do
      category { :switch }
    end

    trait :cashback do
      category { :cashback }
    end

    trait :available do
      available { true }
    end

    trait :unavailable do
      available { false }
    end

    contractor_type { :normal }
    category { :purchase }
    dealer_type { :cbm }
    product_id { 1 }
    available { true }
  end
end
