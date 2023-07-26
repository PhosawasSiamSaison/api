# == Schema Information
#
# Table name: contractor_user_pdpa_versions
#
#  id                   :bigint(8)        not null, primary key
#  contractor_user_id   :bigint(8)        not null
#  pdpa_version_id      :bigint(8)        not null
#  agreed               :boolean          default(TRUE), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#

FactoryBot.define do
  factory :contractor_user_pdpa_version do
    association :contractor_user
    association :pdpa_version
    agreed { true }
  end
end
