# frozen_string_literal: true
# == Schema Information
#
# Table name: one_time_passcodes
#
#  id           :bigint(8)        not null, primary key
#  token        :string(30)       not null
#  passcode     :string(255)      not null
#  expires_at   :datetime         not null
#  deleted      :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  lock_version :integer          default(0)
#

class OneTimePasscode < ApplicationRecord
  validates :token, presence: true
  validates :passcode, presence: true
  validates :expires_at, presence: true

  def expired?
    expires_at < Time.zone.now
  end
end
