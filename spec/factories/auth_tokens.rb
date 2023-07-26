# == Schema Information
#
# Table name: auth_tokens
#
#  id                   :bigint(8)        not null, primary key
#  tokenable_type       :string(255)
#  tokenable_id         :bigint(8)
#  token                :string(30)       not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :auth_token do
    token { SecureRandom.urlsafe_base64 }

    trait :jv do
      association :tokenable, factory: :jv_user
    end

    trait :contractor do
      association :tokenable, factory: :contractor_user
    end

    trait :dealer do
      association :tokenable, factory: :dealer_user
    end

    trait :project_manager do
      association :tokenable, factory: :project_manager_user
    end
  end
end
