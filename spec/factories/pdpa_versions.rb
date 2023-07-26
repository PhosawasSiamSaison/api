# frozen_string_literal: true

# == Schema Information
#
# Table name: pdpa_versions
#
#  id                   :bigint(8)        not null, primary key
#  version              :integer          default(1), not null
#  file_url             :string(255)      not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#


FactoryBot.define do
  factory :pdpa_version do
    sequence(:version)
    file_url { "url_#{version}" }
  end
end
