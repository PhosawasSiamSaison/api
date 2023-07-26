# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_07_12_095742) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.datetime "operation_updated_at"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "operation_updated_at"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "adjust_repayment_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "installment_id", null: false
    t.bigint "created_user_id"
    t.string "business_ymd", limit: 8, null: false
    t.decimal "to_exceeded_amount", precision: 10, scale: 2, null: false
    t.text "before_detail_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_id"], name: "index_adjust_repayment_histories_on_contractor_id"
    t.index ["installment_id"], name: "index_adjust_repayment_histories_on_installment_id"
  end

  create_table "applied_dealers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "dealer_id", null: false
    t.integer "sort_number", limit: 1, null: false
    t.string "applied_ymd", limit: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id", "dealer_id"], name: "ix_1", unique: true
    t.index ["contractor_id"], name: "index_applied_dealers_on_contractor_id"
    t.index ["dealer_id"], name: "index_applied_dealers_on_dealer_id"
  end

  create_table "areas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "area_name", limit: 50, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "auth_tokens", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "tokenable_type"
    t.bigint "tokenable_id"
    t.string "token", limit: 30, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["tokenable_type", "tokenable_id"], name: "index_auth_tokens_on_tokenable_type_and_tokenable_id"
  end

  create_table "available_products", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.integer "category", limit: 1, null: false
    t.bigint "product_id", null: false
    t.integer "dealer_type", limit: 1, null: false
    t.boolean "available", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id", "category", "product_id", "dealer_type"], name: "ix_1", unique: true
    t.index ["contractor_id"], name: "index_available_products_on_contractor_id"
    t.index ["product_id"], name: "index_available_products_on_product_id"
  end

  create_table "business_days", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "business_ymd", limit: 8, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "calculate_late_charges", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "calculate_payment_and_installment_id", null: false
    t.integer "installment_id", null: false
    t.string "payment_ymd", limit: 8, null: false
    t.string "due_ymd", limit: 8, null: false
    t.string "late_charge_start_ymd", limit: 8
    t.string "calc_start_ymd", limit: 8
    t.integer "late_charge_days"
    t.integer "delay_penalty_rate"
    t.decimal "remaining_amount_without_late_charge", precision: 10, scale: 2, default: "0.0"
    t.string "calced_amount"
    t.string "calced_days"
    t.decimal "original_late_charge_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "calc_paid_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_late_charge_before_late_charge_start_ymd", precision: 10, scale: 2, default: "0.0"
    t.decimal "calc_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "calculate_payment_and_installments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "payment_id", null: false
    t.integer "installment_id", null: false
    t.string "business_ymd", limit: 8, null: false
    t.string "payment_ymd", limit: 8, null: false
    t.string "due_ymd", limit: 8, null: false
    t.decimal "input_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_exceeded", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_cashback", precision: 10, scale: 2, default: "0.0"
    t.decimal "subtract_exceeded", precision: 10, scale: 2, default: "0.0"
    t.decimal "subtract_cashback", precision: 10, scale: 2, default: "0.0"
    t.decimal "remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "payment_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_exceeded_remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_cashback_remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_input_amount_remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_exceeded_remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_cashback_remaining_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_exceeded_remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_cashback_remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_input_amount_remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_exceeded_remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_cashback_remaining_interest", precision: 10, scale: 2, default: "0.0"
    t.decimal "remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_input_amount_remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_exceeded_remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "after_cashback_remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_exceeded_remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_cashback_remaining_principal", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_total_exceeded", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_total_cashback", precision: 10, scale: 2, default: "0.0"
    t.decimal "paid_exceeded_and_cashback_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "gain_exceeded_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "gain_cashback_amount", precision: 10, scale: 2, default: "0.0"
    t.boolean "is_exemption_late_charge", default: false
    t.decimal "exemption_late_charge", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_exemption_late_charge", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "cashback_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.integer "point_type", limit: 1, null: false
    t.decimal "cashback_amount", precision: 10, scale: 2, null: false
    t.boolean "latest", null: false
    t.decimal "total", precision: 10, scale: 2, null: false
    t.string "exec_ymd", limit: 8, null: false
    t.string "notes", limit: 100
    t.integer "order_id"
    t.bigint "receive_amount_history_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["receive_amount_history_id"], name: "index_cashback_histories_on_receive_amount_history_id"
  end

  create_table "change_product_applies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id"
    t.string "due_ymd", limit: 8, null: false
    t.datetime "completed_at"
    t.string "memo", limit: 500
    t.integer "apply_user_id"
    t.integer "register_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_change_product_applies_on_contractor_id"
  end

  create_table "contractor_billing_data", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.string "th_company_name"
    t.string "address"
    t.string "tax_id", limit: 13, null: false
    t.string "due_ymd", limit: 8, null: false
    t.decimal "credit_limit", precision: 13, scale: 2
    t.decimal "available_balance", precision: 13, scale: 2
    t.decimal "due_amount", precision: 13, scale: 2
    t.string "cut_off_ymd", limit: 8, null: false
    t.text "installments_json"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_id", "due_ymd"], name: "index_contractor_billing_data_on_contractor_id_and_due_ymd", unique: true
    t.index ["contractor_id"], name: "index_contractor_billing_data_on_contractor_id"
  end

  create_table "contractor_billing_zip_ymds", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "due_ymd", limit: 8, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
  end

  create_table "contractor_user_pdpa_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_user_id", null: false
    t.bigint "pdpa_version_id", null: false
    t.boolean "agreed", default: true, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_user_id", "pdpa_version_id"], name: "ix_1", unique: true
    t.index ["contractor_user_id"], name: "index_contractor_user_pdpa_versions_on_contractor_user_id"
    t.index ["pdpa_version_id"], name: "index_contractor_user_pdpa_versions_on_pdpa_version_id"
  end

  create_table "contractor_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.integer "user_type", limit: 1, default: 0, null: false
    t.string "user_name", limit: 20, null: false
    t.string "full_name", limit: 40, null: false
    t.string "mobile_number", limit: 15
    t.string "title_division", limit: 40
    t.string "email", limit: 200
    t.string "line_id", limit: 20
    t.string "line_user_id"
    t.string "line_nonce"
    t.string "initialize_token", limit: 30
    t.integer "verify_mode", limit: 1, default: 1, null: false
    t.string "verify_mode_otp", limit: 10
    t.integer "login_failed_count", default: 0, null: false
    t.string "rudy_passcode", limit: 10
    t.datetime "rudy_passcode_created_at"
    t.string "rudy_auth_token", limit: 30
    t.string "password_digest"
    t.string "temp_password", limit: 15
    t.string "create_user_type"
    t.integer "create_user_id"
    t.string "update_user_type"
    t.integer "update_user_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["create_user_type", "create_user_id"], name: "index_contractor_users_on_create_user_type_and_create_user_id"
    t.index ["update_user_type", "update_user_id"], name: "index_contractor_users_on_update_user_type_and_update_user_id"
  end

  create_table "contractors", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "tax_id", limit: 15, null: false
    t.integer "contractor_type", limit: 1, default: 1, null: false
    t.integer "main_dealer_id"
    t.boolean "use_only_credit_limit", default: false, null: false
    t.integer "application_type", limit: 1, null: false
    t.integer "approval_status", limit: 1, null: false
    t.string "application_number", limit: 20
    t.datetime "registered_at"
    t.integer "register_user_id", comment: "本登録ユーザ"
    t.boolean "enable_rudy_confirm_payment", default: true
    t.decimal "pool_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "delay_penalty_rate", limit: 2, default: 18, null: false, comment: "遅損金の率。整数で保持する"
    t.boolean "is_switch_unavailable", default: false, null: false
    t.integer "status", limit: 1, default: 1, null: false
    t.integer "exemption_late_charge_count", limit: 2, default: 0, null: false
    t.integer "project_exemption_late_charge_count", limit: 2, default: 0, null: false
    t.boolean "check_payment", default: false, null: false
    t.boolean "stop_payment_sms", default: false, null: false
    t.text "notes"
    t.datetime "notes_updated_at", comment: "Notes更新日"
    t.integer "notes_update_user_id", comment: "Notes更新ユーザID"
    t.boolean "doc_company_registration", default: false, null: false
    t.boolean "doc_vat_registration", default: false, null: false
    t.boolean "doc_owner_id_card", default: false, null: false
    t.boolean "doc_authorized_user_id_card", default: false, null: false
    t.boolean "doc_bank_statement", default: false, null: false
    t.boolean "doc_tax_report", default: false, null: false
    t.string "th_company_name", limit: 100
    t.string "en_company_name", limit: 100
    t.string "address", limit: 200
    t.string "phone_number", limit: 20
    t.string "registration_no", limit: 30
    t.string "establish_year", limit: 4
    t.string "establish_month", limit: 2
    t.string "employee_count", limit: 6
    t.string "capital_fund_mil", limit: 20
    t.decimal "shareholders_equity", precision: 20, scale: 2
    t.decimal "recent_revenue", precision: 20, scale: 2
    t.decimal "short_term_loan", precision: 20, scale: 2
    t.decimal "long_term_loan", precision: 20, scale: 2
    t.decimal "recent_profit", precision: 20, scale: 2
    t.string "apply_from"
    t.string "th_owner_name", limit: 40
    t.string "en_owner_name", limit: 40
    t.string "owner_address", limit: 200
    t.integer "owner_sex", limit: 1
    t.string "owner_birth_ymd", limit: 8
    t.string "owner_personal_id", limit: 20
    t.string "owner_email", limit: 200
    t.string "owner_mobile_number", limit: 15
    t.string "owner_line_id", limit: 20
    t.boolean "authorized_person_same_as_owner", default: false, null: false
    t.string "authorized_person_name", limit: 40
    t.string "authorized_person_title_division", limit: 40
    t.string "authorized_person_personal_id", limit: 20
    t.string "authorized_person_email", limit: 200
    t.string "authorized_person_mobile_number", limit: 15
    t.string "authorized_person_line_id", limit: 20
    t.boolean "contact_person_same_as_owner", default: false, null: false
    t.boolean "contact_person_same_as_authorized_person", default: false, null: false
    t.string "contact_person_name", limit: 40
    t.string "contact_person_title_division", limit: 40
    t.string "contact_person_personal_id", limit: 20
    t.string "contact_person_email", limit: 200
    t.string "contact_person_mobile_number", limit: 15
    t.string "contact_person_line_id", limit: 20
    t.datetime "approved_at", comment: "審査許可日"
    t.integer "approval_user_id"
    t.integer "update_user_id"
    t.string "online_apply_token", limit: 30, comment: "本人確認画像のアップロード時に必要"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "rejected_at", comment: "審査不許可日"
    t.integer "reject_user_id", comment: "審査不許可ユーザ"
    t.datetime "created_at", null: false
    t.integer "create_user_id", comment: "データ作成者"
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.datetime "qr_code_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "dealer_limits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "eligibility_id"
    t.bigint "dealer_id"
    t.decimal "limit_amount", precision: 13, scale: 2, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["dealer_id"], name: "index_dealer_limits_on_dealer_id"
    t.index ["eligibility_id", "dealer_id"], name: "ix_1", unique: true
    t.index ["eligibility_id"], name: "index_dealer_limits_on_eligibility_id"
  end

  create_table "dealer_purchase_of_months", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "dealer_id"
    t.string "month", limit: 6
    t.decimal "purchase_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "order_count", default: 0, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["dealer_id", "month"], name: "index_dealer_purchase_of_months_on_dealer_id_and_month", unique: true
    t.index ["dealer_id"], name: "index_dealer_purchase_of_months_on_dealer_id"
  end

  create_table "dealer_type_limits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "eligibility_id"
    t.integer "dealer_type", limit: 1, default: 1, null: false
    t.decimal "limit_amount", precision: 13, scale: 2, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["eligibility_id", "dealer_type"], name: "ix_1", unique: true
    t.index ["eligibility_id"], name: "index_dealer_type_limits_on_eligibility_id"
  end

  create_table "dealer_type_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "dealer_type", limit: 1, null: false
    t.string "dealer_type_code", limit: 40, null: false, comment: "クライアントツールで分類を見やすくするためのカラム"
    t.integer "group_type", limit: 1, default: 0, null: false
    t.boolean "switch_auto_approval", default: true, null: false
    t.string "sms_line_account", null: false
    t.string "sms_contact_info", limit: 150, null: false
    t.string "sms_servcie_name", limit: 150, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["dealer_type"], name: "ix_1", unique: true
  end

  create_table "dealer_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "dealer_id", null: false
    t.integer "user_type", limit: 1, null: false
    t.string "user_name", limit: 20, collation: "utf8mb3_bin"
    t.string "full_name", limit: 40, null: false
    t.string "mobile_number", limit: 11
    t.string "email", limit: 200
    t.datetime "agreed_at"
    t.string "password_digest", null: false
    t.string "temp_password"
    t.string "create_user_type"
    t.integer "create_user_id", null: false
    t.string "update_user_type"
    t.integer "update_user_id", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["create_user_type", "create_user_id"], name: "index_dealer_users_on_create_user_type_and_create_user_id"
    t.index ["update_user_type", "update_user_id"], name: "index_dealer_users_on_update_user_type_and_update_user_id"
  end

  create_table "dealers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "tax_id", limit: 13, null: false
    t.integer "area_id", null: false
    t.integer "dealer_type", limit: 1, null: false
    t.string "dealer_code", limit: 20, null: false
    t.decimal "for_normal_rate", precision: 5, scale: 2, default: "2.0", null: false, comment: "for Transaction Fee"
    t.decimal "for_government_rate", precision: 5, scale: 2, default: "1.75", comment: "for Transaction Fee"
    t.decimal "for_sub_dealer_rate", precision: 5, scale: 2, default: "1.5", comment: "for Transaction Fee"
    t.decimal "for_individual_rate", precision: 5, scale: 2, default: "1.5", comment: "for Transaction Fee"
    t.string "dealer_name", limit: 50
    t.string "en_dealer_name", limit: 50
    t.string "bank_account", limit: 1000
    t.string "address", limit: 1000
    t.decimal "interest_rate", precision: 5, scale: 2
    t.integer "status", limit: 1, default: 1, null: false
    t.integer "create_user_id"
    t.integer "update_user_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["dealer_code"], name: "index_dealers_on_dealer_code", unique: true
  end

  create_table "delay_penalty_rate_update_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "update_user_id"
    t.integer "old_rate", limit: 1, null: false
    t.integer "new_rate", limit: 1, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_id"], name: "index_delay_penalty_rate_update_histories_on_contractor_id"
    t.index ["update_user_id"], name: "index_delay_penalty_rate_update_histories_on_update_user_id"
  end

  create_table "eligibilities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.decimal "limit_amount", precision: 13, scale: 2, null: false
    t.integer "class_type", limit: 1, null: false
    t.boolean "latest", default: true, null: false
    t.string "comment", limit: 100, null: false
    t.integer "create_user_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "evidences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "contractor_user_id", null: false
    t.bigint "active_storage_blob_id", null: false
    t.string "evidence_number", null: false
    t.text "comment"
    t.datetime "checked_at"
    t.integer "checked_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.index ["active_storage_blob_id"], name: "index_evidences_on_active_storage_blob_id", unique: true
    t.index ["contractor_id"], name: "index_evidences_on_contractor_id"
    t.index ["contractor_user_id"], name: "index_evidences_on_contractor_user_id"
    t.index ["evidence_number"], name: "index_evidences_on_evidence_number", unique: true
  end

  create_table "exemption_late_charges", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "installment_id"
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["installment_id"], name: "index_exemption_late_charges_on_installment_id"
  end

  create_table "global_available_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "contractor_type", limit: 2, null: false
    t.integer "category", limit: 2, null: false
    t.integer "dealer_type", limit: 2, null: false
    t.bigint "product_id", null: false
    t.boolean "available", null: false
    t.bigint "create_user_id"
    t.bigint "update_user_id"
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
    t.index ["contractor_type", "category", "dealer_type", "product_id"], name: "ix_1", unique: true
    t.index ["create_user_id"], name: "index_global_available_settings_on_create_user_id"
    t.index ["product_id"], name: "index_global_available_settings_on_product_id"
    t.index ["update_user_id"], name: "index_global_available_settings_on_update_user_id"
  end

  create_table "installment_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id"
    t.bigint "order_id"
    t.integer "installment_id"
    t.bigint "payment_id"
    t.string "from_ymd"
    t.string "to_ymd", default: "99991231"
    t.decimal "paid_principal", precision: 10, scale: 2, null: false
    t.decimal "paid_interest", precision: 10, scale: 2, null: false
    t.decimal "paid_late_charge", precision: 10, scale: 2, null: false
    t.string "late_charge_start_ymd", limit: 8
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_installment_histories_on_contractor_id"
    t.index ["installment_id", "from_ymd"], name: "index_installment_histories_on_installment_id_and_from_ymd", unique: true
    t.index ["installment_id", "to_ymd"], name: "index_installment_histories_on_installment_id_and_to_ymd", unique: true
    t.index ["order_id"], name: "index_installment_histories_on_order_id"
    t.index ["payment_id"], name: "index_installment_histories_on_payment_id"
  end

  create_table "installments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id"
    t.integer "order_id", null: false
    t.integer "payment_id"
    t.integer "installment_number", limit: 1, null: false
    t.boolean "rescheduled", default: false, null: false
    t.boolean "exempt_late_charge", default: false, null: false
    t.string "due_ymd", limit: 8, null: false
    t.string "paid_up_ymd", limit: 8
    t.decimal "principal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "interest", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_principal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_interest", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_late_charge", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "used_exceeded", precision: 10, scale: 2, default: "0.0"
    t.decimal "used_cashback", precision: 10, scale: 2, default: "0.0"
    t.decimal "reduced_site_limit", precision: 10, scale: 2, default: "0.0"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_installments_on_contractor_id"
  end

  create_table "jv_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "user_type", limit: 1, null: false
    t.boolean "system_admin", default: false, null: false
    t.string "user_name", limit: 20, collation: "utf8mb3_bin"
    t.string "full_name", limit: 40, null: false
    t.string "mobile_number", limit: 11
    t.string "email", limit: 200
    t.string "password_digest", null: false
    t.string "temp_password", limit: 16
    t.integer "create_user_id"
    t.integer "update_user_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "line_spools", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "contractor_user_id", null: false
    t.string "send_to", null: false
    t.text "message_body"
    t.integer "message_type", limit: 1, null: false
    t.integer "send_status", limit: 1, default: 1, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_id"], name: "index_line_spools_on_contractor_id"
    t.index ["contractor_user_id"], name: "index_line_spools_on_contractor_user_id"
  end

  create_table "mail_spools", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id"
    t.string "subject"
    t.text "mail_body"
    t.integer "mail_type", limit: 1, null: false
    t.bigint "contractor_billing_data_id"
    t.integer "send_status", limit: 1, default: 1, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_billing_data_id"], name: "index_mail_spools_on_contractor_billing_data_id"
    t.index ["contractor_id"], name: "index_mail_spools_on_contractor_id"
  end

  create_table "one_time_passcodes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "token", limit: 30, null: false
    t.string "passcode", null: false
    t.datetime "expires_at", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0
  end

  create_table "orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "order_number", null: false
    t.integer "contractor_id", null: false
    t.integer "dealer_id"
    t.bigint "second_dealer_id"
    t.integer "site_id"
    t.bigint "project_phase_site_id"
    t.string "order_type", limit: 30
    t.integer "product_id"
    t.string "bill_date", limit: 15, default: "", null: false
    t.integer "rescheduled_new_order_id"
    t.integer "rescheduled_fee_order_id"
    t.integer "rescheduled_user_id"
    t.datetime "rescheduled_at"
    t.boolean "fee_order", default: false
    t.integer "installment_count", limit: 1, null: false
    t.string "purchase_ymd", limit: 8, null: false
    t.decimal "purchase_amount", precision: 10, scale: 2, null: false
    t.decimal "amount_without_tax", precision: 10, scale: 2
    t.decimal "second_dealer_amount", precision: 10, scale: 2
    t.string "paid_up_ymd", limit: 8
    t.string "input_ymd", limit: 8
    t.datetime "input_ymd_updated_at"
    t.integer "change_product_status", limit: 1, default: 1, null: false
    t.boolean "is_applying_change_product", default: false, null: false
    t.integer "applied_change_product_id"
    t.string "change_product_memo", limit: 200
    t.string "change_product_before_due_ymd", limit: 8
    t.datetime "change_product_applied_at"
    t.datetime "product_changed_at"
    t.integer "product_changed_user_id"
    t.integer "change_product_applied_user_id"
    t.integer "change_product_apply_id"
    t.string "region", limit: 50
    t.integer "order_user_id"
    t.datetime "canceled_at"
    t.integer "canceled_user_id"
    t.string "rudy_purchase_ymd", limit: 8
    t.boolean "uniq_check_flg", default: true, comment: "ユニークチェックから外す場合はnullにする"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["order_number", "dealer_id", "bill_date", "site_id", "uniq_check_flg"], name: "ix_1", unique: true
    t.index ["project_phase_site_id"], name: "index_orders_on_project_phase_site_id"
    t.index ["second_dealer_id"], name: "index_orders_on_second_dealer_id"
  end

  create_table "password_reset_failed_user_names", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "user_name", null: false
    t.boolean "locked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
  end

  create_table "payments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.string "due_ymd", limit: 8, null: false
    t.string "paid_up_ymd", limit: 8
    t.string "paid_up_operated_ymd", limit: 8
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_total_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_exceeded", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_cashback", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "status", limit: 1, default: 1, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "pdpa_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "version", limit: 1, default: 1, null: false
    t.string "file_url", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["version"], name: "ix_1", unique: true
  end

  create_table "products", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "product_key", limit: 1
    t.string "product_name", limit: 40
    t.string "switch_sms_product_name"
    t.integer "number_of_installments", limit: 2
    t.integer "sort_number", limit: 1
    t.decimal "annual_interest_rate", precision: 5, scale: 2
    t.decimal "monthly_interest_rate", precision: 5, scale: 2
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["product_key"], name: "index_products_on_product_key", unique: true
  end

  create_table "project_documents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "file_type", limit: 1, null: false
    t.boolean "ss_staff_only", default: false
    t.string "file_name", limit: 100, null: false
    t.text "comment"
    t.bigint "create_user_id", null: false
    t.bigint "update_user_id", null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
  end

  create_table "project_manager_users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "project_manager_id", null: false
    t.integer "user_type", limit: 1, null: false
    t.string "user_name", limit: 20, collation: "utf8mb3_bin"
    t.string "full_name", limit: 40, null: false
    t.string "mobile_number", limit: 11
    t.string "email", limit: 200
    t.string "password_digest", null: false
    t.string "temp_password", limit: 16
    t.bigint "create_user_id", null: false
    t.bigint "update_user_id", null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
  end

  create_table "project_managers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "tax_id", limit: 13, null: false
    t.string "shop_id", limit: 10
    t.string "project_manager_name", limit: 50, null: false
    t.integer "dealer_type", limit: 1, default: 1, null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
  end

  create_table "project_phase_evidences", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "project_phase_id", null: false
    t.string "evidence_number", limit: 10, null: false
    t.text "comment"
    t.datetime "checked_at"
    t.bigint "checked_user_id"
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
    t.index ["evidence_number"], name: "index_project_phase_evidences_on_evidence_number", unique: true
  end

  create_table "project_phase_sites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "project_phase_id", null: false
    t.bigint "contractor_id", null: false
    t.string "site_code", null: false
    t.string "site_name", null: false
    t.decimal "phase_limit", precision: 10, scale: 2, null: false
    t.decimal "site_limit", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "paid_total_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "refund_amount", precision: 10, scale: 2, default: "0.0"
    t.integer "status", default: 1, null: false
    t.bigint "create_user_id", null: false
    t.bigint "update_user_id", null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
  end

  create_table "project_phases", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "phase_number", null: false
    t.string "phase_name", null: false
    t.decimal "phase_value", precision: 10, scale: 2, null: false
    t.decimal "phase_limit", precision: 10, scale: 2, default: "0.0"
    t.string "start_ymd", limit: 8, null: false
    t.string "finish_ymd", limit: 8, null: false
    t.string "due_ymd", limit: 8, null: false
    t.string "paid_up_ymd", limit: 8
    t.integer "status", limit: 1, default: 1, null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
  end

  create_table "project_photo_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "file_name", limit: 100, null: false
    t.text "comment"
    t.bigint "create_user_id", null: false
    t.bigint "update_user_id", null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
    t.index ["file_name"], name: "index_project_photo_comments_on_file_name", unique: true
  end

  create_table "project_receive_amount_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "project_phase_site_id", null: false
    t.string "receive_ymd", limit: 8, null: false
    t.decimal "receive_amount", precision: 10, scale: 2, null: false
    t.decimal "exemption_late_charge", precision: 10, scale: 2
    t.text "comment"
    t.bigint "create_user_id", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_project_receive_amount_histories_on_contractor_id"
    t.index ["create_user_id"], name: "index_project_receive_amount_histories_on_create_user_id"
    t.index ["project_phase_site_id"], name: "index_project_receive_amount_histories_on_project_phase_site_id"
  end

  create_table "projects", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "project_code", null: false
    t.integer "project_type", limit: 1, null: false
    t.string "project_name", null: false
    t.bigint "project_manager_id", null: false
    t.decimal "project_value", precision: 10, scale: 2
    t.decimal "project_limit", precision: 10, scale: 2, null: false
    t.integer "delay_penalty_rate", limit: 1, null: false
    t.string "project_owner", limit: 40
    t.string "start_ymd", limit: 8, null: false
    t.string "finish_ymd", limit: 8, null: false
    t.string "address", limit: 1000
    t.integer "progress", default: 0, null: false
    t.integer "status", limit: 1, default: 1, null: false
    t.string "contract_registered_ymd", limit: 8, null: false
    t.bigint "create_user_id", null: false
    t.bigint "update_user_id", null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
  end

  create_table "receive_amount_details", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "receive_amount_history_id", null: false
    t.string "order_number"
    t.string "dealer_name", limit: 50
    t.integer "dealer_type", limit: 1
    t.string "tax_id", limit: 15
    t.string "th_company_name"
    t.string "en_company_name"
    t.string "bill_date", limit: 15
    t.string "site_code", limit: 15
    t.string "site_name"
    t.string "product_name", limit: 40
    t.integer "installment_number", limit: 1
    t.string "due_ymd", limit: 8
    t.string "input_ymd", limit: 8
    t.datetime "switched_date"
    t.datetime "rescheduled_date"
    t.string "repayment_ymd", limit: 8
    t.decimal "principal", precision: 10, scale: 2
    t.decimal "interest", precision: 10, scale: 2
    t.decimal "late_charge", precision: 10, scale: 2
    t.decimal "paid_principal", precision: 10, scale: 2
    t.decimal "paid_interest", precision: 10, scale: 2
    t.decimal "paid_late_charge", precision: 10, scale: 2
    t.decimal "total_principal", precision: 10, scale: 2
    t.decimal "total_interest", precision: 10, scale: 2
    t.decimal "total_late_charge", precision: 10, scale: 2
    t.decimal "exceeded_occurred_amount", precision: 10, scale: 2
    t.string "exceeded_occurred_ymd", limit: 8
    t.decimal "exceeded_paid_amount", precision: 10, scale: 2
    t.decimal "cashback_paid_amount", precision: 10, scale: 2
    t.decimal "cashback_occurred_amount", precision: 10, scale: 2
    t.decimal "waive_late_charge", precision: 10, scale: 2
    t.bigint "contractor_id", null: false
    t.bigint "payment_id"
    t.bigint "order_id"
    t.bigint "installment_id"
    t.bigint "dealer_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "operation_updated_at"
    t.index ["contractor_id"], name: "index_receive_amount_details_on_contractor_id"
    t.index ["dealer_id"], name: "index_receive_amount_details_on_dealer_id"
    t.index ["installment_id"], name: "index_receive_amount_details_on_installment_id"
    t.index ["order_id"], name: "index_receive_amount_details_on_order_id"
    t.index ["payment_id"], name: "index_receive_amount_details_on_payment_id"
    t.index ["receive_amount_history_id"], name: "index_receive_amount_details_on_receive_amount_history_id"
  end

  create_table "receive_amount_histories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "contractor_id", null: false
    t.string "receive_ymd", limit: 8, null: false
    t.decimal "receive_amount", precision: 10, scale: 2, null: false
    t.decimal "exemption_late_charge", precision: 10, scale: 2
    t.text "comment", null: false
    t.string "repayment_id", limit: 32, comment: "RUDY 自動消し込み 重複チェック用"
    t.integer "create_user_id"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["repayment_id"], name: "index_receive_amount_histories_on_repayment_id", unique: true
  end

  create_table "rudy_api_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "user_name"
    t.string "password"
    t.string "bearer"
    t.text "response_header_text"
    t.text "response_text"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "scoring_class_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.integer "class_a_min", null: false
    t.integer "class_b_min", null: false
    t.integer "class_c_min", null: false
    t.decimal "class_a_limit_amount", precision: 10, scale: 2, null: false
    t.decimal "class_b_limit_amount", precision: 10, scale: 2, null: false
    t.decimal "class_c_limit_amount", precision: 10, scale: 2, null: false
    t.boolean "latest", default: false, null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lock_version", default: 0
  end

  create_table "scoring_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.string "comment", limit: 1000, null: false
    t.integer "create_user_id", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_scoring_comments_on_contractor_id"
  end

  create_table "scoring_results", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.bigint "scoring_class_setting_id", null: false
    t.decimal "limit_amount", precision: 20, scale: 2, null: false
    t.integer "class_type", limit: 1, null: false
    t.integer "financial_info_fiscal_year"
    t.integer "years_in_business"
    t.decimal "register_capital", precision: 20, scale: 2
    t.decimal "shareholders_equity", precision: 20, scale: 2
    t.decimal "total_revenue", precision: 20, scale: 2
    t.decimal "net_revenue", precision: 20, scale: 2
    t.decimal "current_ratio", precision: 10, scale: 2
    t.decimal "de_ratio", precision: 10, scale: 2
    t.integer "years_in_business_score"
    t.integer "register_capital_score"
    t.integer "shareholders_equity_score"
    t.integer "total_revenue_score"
    t.integer "net_revenue_score"
    t.integer "current_ratio_score"
    t.integer "de_ratio_score"
    t.integer "total_score"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_scoring_results_on_contractor_id"
    t.index ["scoring_class_setting_id"], name: "index_scoring_results_on_scoring_class_setting_id"
  end

  create_table "send_email_addresses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "mail_spool_id", null: false
    t.bigint "contractor_user_id"
    t.string "send_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.index ["contractor_user_id"], name: "index_send_email_addresses_on_contractor_user_id"
    t.index ["mail_spool_id"], name: "index_send_email_addresses_on_mail_spool_id"
  end

  create_table "site_limit_change_applications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "project_phase_site_id", null: false
    t.decimal "site_limit", precision: 13, scale: 2, null: false
    t.boolean "approved", default: false, null: false
    t.integer "deleted", limit: 1, default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0, null: false
    t.index ["project_phase_site_id"], name: "index_site_limit_change_applications_on_project_phase_site_id"
  end

  create_table "sites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id"
    t.bigint "dealer_id", null: false
    t.boolean "is_project", default: false, null: false
    t.string "site_code", limit: 15, null: false
    t.string "site_name", null: false
    t.decimal "site_credit_limit", precision: 13, scale: 2, null: false
    t.boolean "closed", default: false, null: false
    t.integer "create_user_id", null: false
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_id"], name: "index_sites_on_contractor_id"
    t.index ["dealer_id"], name: "index_sites_on_dealer_id"
  end

  create_table "sms_spools", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_id"
    t.integer "contractor_user_id"
    t.string "send_to", null: false
    t.text "message_body"
    t.integer "message_type", limit: 1, null: false
    t.integer "send_status", limit: 1, default: 1, null: false
    t.integer "sms_provider"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.integer "lock_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.index ["contractor_id"], name: "index_sms_spools_on_contractor_id"
  end

  create_table "system_settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.string "front_jv_version"
    t.string "front_c_version"
    t.string "front_d_version"
    t.string "front_pm_version"
    t.integer "verify_mode", default: 1, null: false
    t.integer "sms_provider", default: 2, null: false
    t.boolean "is_downloading_csv", default: false, null: false
    t.integer "integrated_terms_of_service_version", default: 1, null: false
    t.integer "cbm_terms_of_service_version", default: 0, null: false
    t.integer "cpac_terms_of_service_version", default: 0, null: false
    t.integer "global_house_terms_of_service_version", default: 1, null: false
    t.integer "transformer_terms_of_service_version", default: 1, null: false
    t.integer "solution_terms_of_service_version", default: 1, null: false
    t.integer "b2b_terms_of_service_version", default: 1, null: false
    t.integer "q_mix_terms_of_service_version", default: 1, null: false
    t.integer "nam_terms_of_service_version", default: 1, null: false
    t.integer "bigth_terms_of_service_version", default: 1, null: false
    t.integer "permsin_terms_of_service_version", default: 1, null: false
    t.integer "scgp_terms_of_service_version", default: 1, null: false
    t.integer "rakmao_terms_of_service_version", default: 1, null: false
    t.integer "cotto_terms_of_service_version", default: 1, null: false
    t.integer "d_gov_terms_of_service_version", default: 1, null: false
    t.integer "sub_dealer_terms_of_service_version", default: 1, null: false
    t.integer "individual_terms_of_service_version", default: 1, null: false
    t.decimal "credit_limit_additional_rate", precision: 5, scale: 2
    t.integer "order_one_time_passcode_limit", default: 15, comment: "分単位"
    t.integer "deleted", limit: 1, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
  end

  create_table "terms_of_service_versions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb3", force: :cascade do |t|
    t.bigint "contractor_user_id"
    t.integer "dealer_type", limit: 1
    t.boolean "sub_dealer", default: false, null: false
    t.boolean "integrated", default: false, null: false, comment: "統合版の規約タイプの判定カラム"
    t.boolean "individual", default: false, null: false
    t.integer "version", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "operation_updated_at"
    t.integer "lock_version", default: 0
    t.index ["contractor_user_id", "dealer_type", "sub_dealer"], name: "ix_1", unique: true
    t.index ["contractor_user_id"], name: "index_terms_of_service_versions_on_contractor_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "adjust_repayment_histories", "contractors"
  add_foreign_key "adjust_repayment_histories", "installments"
  add_foreign_key "applied_dealers", "contractors"
  add_foreign_key "applied_dealers", "dealers"
  add_foreign_key "available_products", "contractors"
  add_foreign_key "available_products", "products"
  add_foreign_key "change_product_applies", "contractors"
  add_foreign_key "contractor_billing_data", "contractors"
  add_foreign_key "contractor_user_pdpa_versions", "contractor_users"
  add_foreign_key "contractor_user_pdpa_versions", "pdpa_versions"
  add_foreign_key "dealer_limits", "dealers"
  add_foreign_key "dealer_limits", "eligibilities"
  add_foreign_key "dealer_purchase_of_months", "dealers"
  add_foreign_key "dealer_type_limits", "eligibilities"
  add_foreign_key "delay_penalty_rate_update_histories", "contractors"
  add_foreign_key "delay_penalty_rate_update_histories", "jv_users", column: "update_user_id"
  add_foreign_key "exemption_late_charges", "installments"
  add_foreign_key "global_available_settings", "jv_users", column: "create_user_id"
  add_foreign_key "global_available_settings", "jv_users", column: "update_user_id"
  add_foreign_key "installment_histories", "contractors"
  add_foreign_key "installment_histories", "orders"
  add_foreign_key "installment_histories", "payments"
  add_foreign_key "installments", "contractors"
  add_foreign_key "line_spools", "contractor_users"
  add_foreign_key "line_spools", "contractors"
  add_foreign_key "mail_spools", "contractor_billing_data", column: "contractor_billing_data_id"
  add_foreign_key "mail_spools", "contractors"
  add_foreign_key "orders", "dealers", column: "second_dealer_id"
  add_foreign_key "orders", "project_phase_sites"
  add_foreign_key "project_receive_amount_histories", "contractors"
  add_foreign_key "project_receive_amount_histories", "jv_users", column: "create_user_id"
  add_foreign_key "project_receive_amount_histories", "project_phase_sites"
  add_foreign_key "receive_amount_details", "contractors"
  add_foreign_key "receive_amount_details", "dealers"
  add_foreign_key "receive_amount_details", "installments"
  add_foreign_key "receive_amount_details", "orders"
  add_foreign_key "receive_amount_details", "payments"
  add_foreign_key "receive_amount_details", "receive_amount_histories"
  add_foreign_key "scoring_comments", "contractors"
  add_foreign_key "scoring_results", "contractors"
  add_foreign_key "scoring_results", "scoring_class_settings"
  add_foreign_key "sites", "contractors"
  add_foreign_key "sites", "dealers"
  add_foreign_key "sms_spools", "contractors"
  add_foreign_key "terms_of_service_versions", "contractor_users"
end
