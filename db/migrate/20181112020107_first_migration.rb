class FirstMigration < ActiveRecord::Migration[5.2]
  def change
    create_table :jv_users do |t|
      t.string  :user_key, limit: 10, null: false
      t.integer :user_type, limit: 1, null: false
      t.string  :user_name, limit: 20, null: false
      t.string  :mobile_number, limit: 11, null: false
      t.string  :sms_auth_number, limit: 6
      t.integer :login_failed_count, limit: 1, null: false, default: 0
      t.boolean :locked, null: false, default: false
      t.string  :password_digest, null: false
      t.string  :temp_password, limit: 16
      t.integer  :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer  :lock_version,                                default: 0
    end

    create_table :contractors do |t|
      t.string  :tax_id, limit: 15
      t.integer :dealer_id, null: false
      t.string  :company_key,	limit: 20
      t.integer :application_type, limit: 1, null: false
      t.string  :reception_number, limit: 10
      t.integer :approval_status,	limit: 1, null: false
      t.integer :amount_limit
      t.boolean :rejected, null: false, default: false
      t.integer :approval_user_id, null: false
      t.boolean :available,	null: false, default: false
      # Company Info          
      t.string  :corporation_name, limit: 50
      t.integer :business_history
      t.integer :capital_stock
      t.integer :employee_count
      t.integer :sales_amount
      t.string  :address, limit: 100
      t.string  :phone_number, limit: 20
      t.string  :email, limit: 200
      t.string  :rep_name, limit: 20
      t.integer :rep_sex, limit: 1
      t.string  :rep_bird_ymd, limit: 8
      t.integer :deleted,          limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :contractor_users do |t|
      t.integer :user_type, limit: 1, null: false
      t.string  :user_name, limit: 20, null: false
      t.string  :mobile_number, limit: 11
      t.string  :sms_auth_number, limit: 6
      t.integer :login_failed_count, limit: 1, null: false, default: 0
      t.boolean :locked, null: false, default: false
      t.string  :password_digest, limit: 255
      t.string  :temp_password, limit: 15
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :limit_change_history do |t|
      t.integer :contractor_id, null: false
      t.integer :limit_amount, null: false
      t.integer :update_user_id, null: false
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :dealers do |t|
      t.string  :shop_name, limit: 20, null: false
      t.integer :area_id, null: false
      t.string  :phone_number, limit: 20
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :dealer_users do |t|
      t.integer :dealer_id, null: false
      t.integer :user_type, limit: 1, null: false
      t.string  :user_name, limit: 20, null: false
      t.string  :mobile_number, limit: 11, null: false
      t.string  :sms_auth_number, limit: 6
      t.integer :status, limit: 1, null: false, default: "enable"
      t.integer :login_failed_count, limit: 1, null: false, default: 0
      t.boolean :locked, null: false, default: false
      t.string  :password_digest, limit: 255, null: false
      t.string  :temp_password, linit: 15
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :transactions do |t|
      t.integer :contractor_id, null: false
      t.string :order_number, limit: 20, null: false
      t.integer :purchase_amount, null: false
      t.integer :order_quantity, null: false
      t.string :purchase_ymd, limit: 8, null: false
      t.integer :installment_count, null: false
      t.integer :interest_rate
      t.integer :commition
      t.integer :paid_up_amount
      t.string :delivery_address, limit: 100
      t.boolean :item_received, null: false, default: false
      t.string :pay_to_dealer_plan_ymd, limit: 8
      t.boolean :paid_to_dealer, null: false, default: false
      t.boolean :paid_off, null: false, default: false
      t.string :paid_off_ymd, limit: 8
      t.integer :create_dealer_user_id, null: false
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :deliveries do |t|
      t.integer :transaction_id, null: false
      t.string :delivery_number, limit: 20, null: false
      t.integer :delivery_status, limit: 1, null: false, default: "on_delivery"
      t.string :delivery_schedule_ymd, limit: 8
      t.string :delivery_done_ymd, limit: 8
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :installments do |t|
      t.integer :transaction_id, null: false
      t.integer :installment_number, limit: 1, null: false
      t.string :disbursement_schedule_ymd, limit: 8, null: false
      t.integer :disbursement_schedule_amount, null: false
      t.integer :paid_amount
      t.integer :delay_payment_amount
      t.boolean :paid, null: false, default: false
      t.string :closing_ymd, limit: 8
      t.boolean :invoiced, null: false, default: false
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :point_history do |t|
      t.integer :contractor_id, null: false
      t.integer :point_type, limit: 1, null: false
      t.integer :quantity, null: false
      t.boolean :latest_flg, null: false
      t.integer :total, null: false
      t.string  :exec_ymd, limit: 8, null: false
      t.string  :notes, limit: 100
      t.integer :transaction_id
      t.integer :installment_id
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :information do |t|
      t.string :title, limit: 20, null: false
      t.text :content
      t.boolean :opened, null: false, default: false
      t.string :open_start_ymd
      t.string :open_end_ymd
      t.string :create_user_type
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :areas do |t|
      t.string :area_name, limit: 20, null: false
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :jv_settings do |t|
      t.text :bank_account_info
      t.string :mobile_number
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end

    create_table :auth_tokens do |t|
      t.integer :jv_user_id
      t.integer :contradtor_user_id
      t.integer :dealer_user_id
      t.string :token, limit: 20, null: false
      t.integer :deleted,         limit: 1,    null: false, default: false
      t.timestamps
      t.integer :lock_version,                                default: 0
    end
  end
end
