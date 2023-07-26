# frozen_string_literal: true
# == Schema Information
#
# Table name: jv_users
#
#  id                   :bigint(8)        not null, primary key
#  user_type            :integer          not null
#  system_admin         :boolean          default(FALSE), not null
#  user_name            :string(20)
#  full_name            :string(40)       not null
#  mobile_number        :string(11)
#  email                :string(200)
#  password_digest      :string(255)      not null
#  temp_password        :string(16)
#  create_user_id       :integer
#  update_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :jv_user, aliases: [:create_user, :update_user]  do
    trait :staff do
      user_type { 'staff' }
    end

    user_type { "md" }
    sequence(:user_name) { |i| "jv_user#{i}" }
    full_name { "JV Taro" }
    mobile_number { "00000000000" }
    sequence(:email) { |i| "jv_user#{i}@example.com" }
    password_digest { BCrypt::Password.create("password") }
    temp_password { "password" }
  end
end
