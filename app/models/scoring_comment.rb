# frozen_string_literal: true
# == Schema Information
#
# Table name: scoring_comments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  comment              :string(1000)     not null
#  create_user_id       :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

class ScoringComment < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :create_user, class_name: :JvUser, unscoped: true

  validates :comment, presence: true, length: { maximum: 1000 }

  def create_user_name
    create_user.full_name
  end
end
