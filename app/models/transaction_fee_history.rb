# frozen_string_literal: true
# == Schema Information
#
# Table name: transaction_fee_history

# t.integer "dealer_id", null: false
# t.string "apply_ymd", limit: 8
# t.decimal "for_normal_rate", precision: 5, scale: 2, default: "2.0", null: false
# t.decimal "for_government_rate", precision: 5, scale: 2, default: "1.75"
# t.decimal "for_sub_dealer_rate", precision: 5, scale: 2, default: "1.5"
# t.decimal "for_individual_rate", precision: 5, scale: 2, default: "1.5"
# t.text "reason"
# t.integer "status", limit: 1, default: 0, null: false
# t.integer "create_user_id"
# t.integer "update_user_id"
# t.integer "deleted", limit: 1, default: 0, null: false
# t.datetime "created_at", precision: 6, null: false
# t.datetime "updated_at", precision: 6, null: false
# t.integer "lock_version", default: 0

class TransactionFeeHistory < ApplicationRecord
  default_scope { where(deleted: 0) }

  belongs_to :create_user, class_name: :JvUser, optional: true, unscoped: true
  belongs_to :update_user, class_name: :JvUser, optional: true, unscoped: true

  belongs_to :dealer

  scope :active_transaction, -> { where(status: "active") }

  scope :apply_ymd_sort, -> { order(apply_ymd: :desc) }

  enum status: { scheduled: 0, active: 1, retired: 2, deleted: 3 }

  validates :for_normal_rate,     presence: true
  validates :for_government_rate, presence: true
  validates :for_sub_dealer_rate, presence: true
  validates :for_individual_rate, presence: true
  validates :reason, presence: true

  validates :for_normal_rate,     numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  validates :for_government_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  validates :for_sub_dealer_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  validates :for_individual_rate, numericality: { greater_than_or_equal_to: 0, less_than: 1000 }, allow_nil: true
  
  validate :apply_ymd_validation, on: :create

  def status_label
    enum_to_label('status')
  end

  def delete_history
    return if active? || retired?

    update!(deleted: true, status: "deleted")
  end

  private
  def apply_ymd_validation
    today_ymd = BusinessDay.today_ymd

    if self.apply_ymd <= today_ymd
        errors.add(
        :apply_ymd,
        :invalid_apply_ymd,
        ymd: today_ymd
      )
    end

    uniq_history = dealer
                   .transaction_fee_histories
                   .find_by(apply_ymd: self.apply_ymd, status: "scheduled")

    if uniq_history.present?
      errors.add(
        :apply_ymd,
        :taken,
        message: "already taken. Please delete current scheduled history to recreate."
      )
    end
  end
end
