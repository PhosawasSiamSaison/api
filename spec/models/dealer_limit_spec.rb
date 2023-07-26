# frozen_string_literal: true

# == Schema Information
#
# Table name: dealer_limits
#
#  id                   :bigint(8)        not null, primary key
#  eligibility_id       :bigint(8)
#  dealer_id            :bigint(8)
#  limit_amount         :decimal(13, 2)   not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#


require 'rails_helper'

RSpec.describe DealerLimit, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }
end
