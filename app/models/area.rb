# frozen_string_literal: true

# == Schema Information
#
# Table name: areas
#
#  id                   :bigint(8)        not null, primary key
#  area_name            :string(50)       not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class Area < ApplicationRecord
  default_scope { where(deleted: 0) }

  has_many :dealers
end
