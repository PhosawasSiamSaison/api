# frozen_string_literal: true
# == Schema Information
#
# Table name: sites
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  dealer_id            :bigint(8)        not null
#  is_project           :boolean          default(FALSE), not null
#  site_code            :string(15)       not null
#  site_name            :string(255)      not null
#  site_credit_limit    :decimal(13, 2)   not null
#  closed               :boolean          default(FALSE), not null
#  create_user_id       :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :site do
    trait :closed do
      closed { true }
    end

    association :contractor
    association :dealer
    sequence(:site_code) { |i| i }
    sequence(:site_name) { |i| "site#{i}" }
    site_credit_limit { 99999999999.0 }
    closed { false }
    association :create_user, factory: :contractor_user
  end
end
