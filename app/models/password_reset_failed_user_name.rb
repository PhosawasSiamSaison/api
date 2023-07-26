# frozen_string_literal: true

class PasswordResetFailedUserName < ApplicationRecord
  # 5分前から現在の範囲の検索条件
  scope :past_5minutes, -> { where(created_at: Time.zone.now - 5.minutes..Time.zone.now) }

  class << self
    def rearched_lock_limit?(user_name)
      # ５分以内に失敗した回数
      all.past_5minutes.where(user_name: user_name).count >= 5
    end

    def locked?(user_name)
      # ５分以内にロックされたレコードがあるか
      all.past_5minutes.exists?(user_name: user_name, locked: true)
    end
  end
end