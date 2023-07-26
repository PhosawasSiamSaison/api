# == Schema Information
#
# Table name: sms_spools
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  contractor_user_id   :integer
#  send_to              :string(255)      not null
#  message_body         :text(65535)
#  message_type         :integer          not null
#  send_status          :integer          default("unsent"), not null
#  sms_provider         :integer
#  deleted              :integer          default(0), not null
#  lock_version         :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#

FactoryBot.define do
  factory :sms_spool do
    trait :done do
      send_status { :done }
    end

    association :contractor
    association :contractor_user
    send_to { '1' }
    message_type { 1 }
    send_status { :unsent }
  end
end
