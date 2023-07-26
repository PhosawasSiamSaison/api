# frozen_string_literal: true
# == Schema Information
#
# Table name: eligibilities
#
#  id             :bigint(8)        not null, primary key
#  contractor_id  :integer          not null
#  limit_amount   :decimal(13, 2)   not null
#  class_type     :integer          not null
#  latest         :boolean          default(TRUE), not null
#  auto_scored    :boolean          default(FALSE), not null
#  comment        :string(100)      not null
#  create_user_id :integer          not null
#  deleted        :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  lock_version   :integer          default(0)
#

FactoryBot.define do
  factory :eligibility do
    transient do
      create_dealer_limit { false }
    end

    trait :create_dealer_limit do
      create_dealer_limit { false }
    end

    after(:create) do |eligibility, evaluator|
      if evaluator.create_dealer_limit
        Dealer.all.each do |dealer|
          FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer,
            limit_amount: eligibility.limit_amount)
        end

        Dealer.dealer_types.keys.each do |dealer_type|
          FactoryBot.create(:dealer_type_limit, eligibility: eligibility, dealer_type: dealer_type,
            limit_amount: eligibility.limit_amount)
        end
      end
    end

    trait :not_latest do
      latest { false }
    end

    class_type { 's_class' }
    latest { true }
    limit_amount { 10000000.0 }
    comment { 'comment' }
    create_user { nil }
  end
end
