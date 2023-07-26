# frozen_string_literal: true
# == Schema Information
#
# Table name: rudy_api_settings
#
#  id                   :bigint(8)        not null, primary key
#  user_name            :string(255)
#  password             :string(255)
#  bearer               :string(255)
#  response_header_text :text(65535)
#  response_text        :text(65535)
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :rudy_api_setting do
    user_name { '' }
    password { '' }
    response_header_text { 'sample header text' }
    response_text { 'sample text' }
  end
end
