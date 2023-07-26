# == Schema Information
#
# Table name: project_manager_users
#
#  id                   :bigint(8)        not null, primary key
#  project_manager_id   :integer          not null
#  user_type            :integer          not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  password_digest      :string(255)      not null
#  temp_password        :string(16)
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

FactoryBot.define do
  factory :project_manager_user do
    trait :staff do
      user_type { 'staff' }
    end

    trait :agreed do
      agreed_at { Time.zone.now }
    end

    association :project_manager, factory: :project_manager
    user_type { "md" }
    sequence(:user_name) { |i| "pm_user#{i}" }
    full_name { "JV Taro" }
    mobile_number { "00000000000" }
    sequence(:email) { |i| "pm_user#{i}@example.com" }
    password_digest { BCrypt::Password.create("password") }
    temp_password { "password" }
    create_user_id { 1 }
    update_user_id { 1 }
  end
end
