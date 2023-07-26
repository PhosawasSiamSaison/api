# == Schema Information
#
# Table name: dealer_users
#
#  id                   :bigint(8)        not null, primary key
#  dealer_id            :integer          not null
#  user_type            :integer          not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  agreed_at            :datetime
#  password_digest      :string(255)      not null
#  temp_password        :string(255)
#  create_user_type     :string(255)
#  create_user_id       :integer          not null
#  update_user_type     :string(255)
#  update_user_id       :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :dealer_user do
    trait :osr do
      user_type { 'osr' }
    end

    user_type                { "owner" }
    sequence(:user_name)     { |i| "dealer_user#{i}" }
    full_name                { "Dealer Taro" }
    sequence(:mobile_number) { |i| format("%0#{9}d", i) }
    sequence(:email)         { |i| "dealer#{i}@example.com" }
    password_digest          { BCrypt::Password.create("password") }
    temp_password            { "password" }
    association :dealer
    association :create_user, factory: :jv_user
    update_user { create_user }
  end
end
