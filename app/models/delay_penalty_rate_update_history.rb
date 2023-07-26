# frozen_string_literal: true

# == Schema Information
#
# Table name: delay_penalty_rate_update_histories
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  update_user_id       :bigint(8)
#  old_rate             :integer          not null
#  new_rate             :integer          not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#


class DelayPenaltyRateUpdateHistory < ApplicationRecord
  include UserModule

  default_scope { where(deleted: 0) }

  belongs_to :contractor
  belongs_to :update_user, class_name: :JvUser, optional: true, unscoped: true

  validates :old_rate, presence: true
  validates :new_rate, presence: true
end
