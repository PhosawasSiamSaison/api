# frozen_string_literal: true
# == Schema Information
#
# Table name: evidences
#
#  id                     :bigint(8)        not null, primary key
#  contractor_id          :bigint(8)        not null
#  contractor_user_id     :bigint(8)        not null
#  active_storage_blob_id :bigint(8)        not null
#  evidence_number        :string(255)      not null
#  comment                :text(65535)
#  checked_at             :datetime
#  checked_user_id        :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  operation_updated_at   :datetime
#

FactoryBot.define do
  factory :evidence do
    trait :checked do
      checked_at { '2019-01-01 00:00:00' }
    end

    association :contractor
    association :contractor_user, factory: :contractor_user
    sequence(:active_storage_blob_id) {|i| i}
    sequence(:evidence_number) {|i| i}
    checked_at { nil }
  end
end
