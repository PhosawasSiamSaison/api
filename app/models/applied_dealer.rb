# frozen_string_literal: true
# == Schema Information
#
# Table name: applied_dealers
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  dealer_id            :bigint(8)        not null
#  sort_number          :integer          not null
#  applied_ymd          :string(8)        not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class AppliedDealer < ApplicationRecord
  belongs_to :contractor
  belongs_to :dealer
end
