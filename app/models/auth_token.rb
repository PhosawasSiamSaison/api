# frozen_string_literal: true
# == Schema Information
#
# Table name: auth_tokens
#
#  id                   :bigint(8)        not null, primary key
#  tokenable_type       :string(255)
#  tokenable_id         :bigint(8)
#  token                :string(30)       not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class AuthToken < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :tokenable, polymorphic: true
end
