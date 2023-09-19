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

FactoryBot.define do
  factory :transaction_fee_history do
    apply_ymd { '20190116' }
    reason { 'new transaction' }
  end
end
