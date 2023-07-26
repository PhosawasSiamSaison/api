# == Schema Information
#
# Table name: contractor_users
#
#  id                       :bigint(8)        not null, primary key
#  contractor_id            :integer          not null
#  user_type                :integer          default(NULL), not null
#  user_name                :string(20)       not null
#  full_name                :string(40)       not null
#  mobile_number            :string(15)
#  title_division           :string(40)
#  email                    :string(200)
#  line_id                  :string(20)
#  line_user_id             :string(255)
#  line_nonce               :string(255)
#  initialize_token         :string(30)
#  verify_mode              :integer          default("verify_mode_otp"), not null
#  verify_mode_otp          :string(10)
#  login_failed_count       :integer          default(0), not null
#  rudy_passcode            :string(10)
#  rudy_passcode_created_at :datetime
#  rudy_auth_token          :string(30)
#  password_digest          :string(255)
#  temp_password            :string(15)
#  create_user_type         :string(255)
#  create_user_id           :integer
#  update_user_type         :string(255)
#  update_user_id           :integer
#  deleted                  :integer          default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  operation_updated_at     :datetime
#  lock_version             :integer          default(0)
#

FactoryBot.define do
  factory :contractor_user do
    user_type                { "owner" }
    sequence(:user_name)     { |i| '1' + format('%012d', i) } # Contractorのユーザ情報と被る可能性があるので先頭を1にする
    full_name                { "Contractor Taro" }
    mobile_number            { "00011112222" }
    login_failed_count       { 0 }
    rudy_passcode            { '123456' }
    rudy_passcode_created_at { Time.zone.now }
    rudy_auth_token          { 'rudy_auth_token' }
    password_digest          { BCrypt::Password.create("123456") }
    temp_password            { nil }
    association :contractor
    create_user { nil }
    update_user { nil }
  end
end
