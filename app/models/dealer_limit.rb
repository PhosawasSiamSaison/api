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


class DealerLimit < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :eligibility
  belongs_to :dealer
end
