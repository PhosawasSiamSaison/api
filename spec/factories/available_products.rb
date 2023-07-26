# == Schema Information
#
# Table name: available_products
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  category             :integer          not null
#  product_id           :bigint(8)        not null
#  dealer_type          :integer          not null
#  available            :boolean          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :available_product do
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

    trait :product1 do
      product_id { 1 }
    end

    trait :product2 do
      product_id { 2 }
    end

    trait :product3 do
      product_id { 3 }
    end

    trait :product4 do
      product_id { 4 }
    end

    trait :product5 do
      product_id { 5 }
    end

    trait :product8 do
      product_id { 8 }
    end

    product_id { 1 }
    category { :purchase }
    dealer_type { :cbm }
    available { true }
  end
end