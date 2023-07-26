# frozen_string_literal: true
# == Schema Information
#
# Table name: business_days
#
#  id                   :bigint(8)        not null, primary key
#  business_ymd         :string(8)        not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :business_day do
    business_ymd { '20190115' }
  end
end
