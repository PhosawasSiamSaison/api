class ThirdMigration < ActiveRecord::Migration[5.2]
  def change
    # jv_users
    drop_table :jv_users
    create_table :jv_users do |t|
      t.integer :user_type, limit: 1, null: false
      t.string  :user_name, limit: 20, null: false
      t.string  :full_name, limit: 20, null: false
      t.string  :mobile_number, limit: 11, null: false
      t.integer :login_failed_count, limit: 1, null: false, default: 0
      t.string  :sms_auth_token, limit: 30
      t.string  :password_digest, null: false
      t.string  :temp_password, limit: 16
      t.integer :status, limit: 1, null: false, default: 0

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # contractors
    drop_table :contractors
    create_table :contractors do |t|
      t.integer :main_dealer_id, null: false
      t.integer :application_type, limit: 1, null: false
      t.integer :approval_status, limit: 1, null: false
      t.string  :tax_id, limit: 15
      t.decimal :pool_amount, null: false, default: 0.00
      t.string :th_company_name, limit: 50
      t.string :en_company_name, limit: 50
      t.string :address, limit: 100
      t.string :phone_number, limit: 20
      t.string :registration_no, limit: 30
      t.string :establish_ymd, limit: 8
      t.string :employee_count, limit: 6
      t.string :capital_fund_mil, limit: 20
      t.string :th_owner_name, limit: 20
      t.string :en_owner_name, limit: 20
      t.string :owner_address, limit: 100
      t.string :owner_personal_id, limit: 20
      t.string :owner_line_id, limit: 20
      t.integer :owner_sex, limit: 1
      t.string :owner_bird_ymd, limit: 8
      t.string :owner_mobile_number, limit: 15
      t.string :owner_email, limit: 200

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # contractor_users
    drop_table :contractor_users
    create_table :contractor_users do |t|
      t.integer :contractor_id, null: false
      t.string  :user_name, limit: 20, null: false
      t.string  :full_name, limit: 20, null: false
      t.string  :personal_id, limit: 20
      t.string  :mobile_number, limit: 15
      t.string  :title_division, limit: 20
      t.string  :email, limit: 200
      t.string :line_id, limit: 20
      t.string :sms_auth_token, limit: 30
      t.integer :login_failed_count, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.string :password_digest
      t.string :temp_password, limit: 15

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # limit_change_history
    drop_table :limit_change_histories
    create_table :limit_change_histories do |t|
      t.integer :contractor_id, null: false
      t.integer :limit_amount, null: false
      t.integer :class_type, limit: 1, null: false
      t.integer :update_user_id, null: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # dealers
    drop_table :dealers
    create_table :dealers do |t|
      t.integer :area_id, null: false
      t.string :dealer_name, limit: 20
      t.string :registered_ymd, limit: 8
      t.integer :status, limit: 1, null: false, default: 0

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # dealer_users
    drop_table :dealer_users
    create_table :dealer_users do |t|
      t.integer :dealer_id, null: false
      t.integer :user_type, limit: 1, null: false
      t.string  :user_name, limit: 20, null: false
      t.string  :full_name, limit: 20, null: false
      t.string  :mobile_number, limit: 11
      t.string  :email, limit: 200
      t.integer :status, limit: 1, null: false
      t.string  :sms_auth_token, limit: 30
      t.integer :login_failed_count, limit: 1, null: false, default: 0
      t.string  :password_digest, limit: 255, null: false
      t.string  :temp_password, linit: 15

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # orders
    drop_table :transactions
    create_table :orders do |t|
      t.integer :contractor_id, null: false
      t.integer :area_id, null: false
      t.integer :dealer_id, null: false
      t.string :order_number, limit: 20, null: false
      t.integer :payment_id
      t.decimal :purchase_amount
      t.integer :order_quantity, null: false
      t.string :purchase_ymd, limit: 8, null: false
      t.integer :repayment_count, null: false
      t.decimal :interest_rate, precision: 5, scale: 2
      t.decimal :commission, precision: 5, scale: 2
      t.decimal :paid_up_amount
      t.boolean :item_received, null: false, default: false
      t.string :pay_to_dealer_plan_ymd, limit: 8
      t.boolean :paid_to_dealer, null: false, default: false
      t.boolean :paid_off, null: false, default: false
      t.string :paid_off_ymd, limit: 8
      t.boolean :send_invoice, null: false, default: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # deliveries
    drop_table :deliveries

    # repayments
    create_table :repayments do |t|
      t.integer :order_id, null: false
      t.integer :repayment_number, limit: 1, null: false
      t.string  :repayment_schedule_ymd, limit: 8, null: false
      t.decimal :repayment_schedule_amount, null: false
      t.string  :paid_ymd, limit: 8
      t.decimal :paid_amount
      t.boolean :delayed
      t.decimal :delay_repayment_amount
      t.boolean :jv_checked, null: false, default: false
      t.boolean :batch_checked, null: false, default: false
      t.boolean :last_repayment, null: false, default: false
      t.string  :closing_ymd, limit: 8

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # payments
    create_table :payments do |t|
      t.integer :dealer_id, null: false
      t.integer :order_count
      t.decimal :sales_total
      t.decimal :affiliation_fee
      t.decimal :payment_amount
      t.string  :payment_schedule_ymd, limit: 8
      t.integer :status

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # cashback_history
    drop_table :point_histories
    create_table :cashback_history do |t|
      t.integer :contractor_id, null: false
      t.integer :point_type, limit: 1, null: false
      t.integer :quantity, null: false
      t.boolean :latest_flg, null: false
      t.integer :total, null: false
      t.string  :exec_ymd, limit: 8, null: false
      t.string  :notes, limit: 100
      t.integer :order_id
      t.integer :repayment_id

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # info
    drop_table :information
    create_table :information do |t|
      t.string :title, limit: 20, null: false
      t.text :content
      t.boolean :opened, null: false, default: false
      t.string :open_start_ymd
      t.string :open_end_ymd
      t.string :create_user_type

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # dealers_infos
    create_table :dealers_infos do |t|
      t.integer :dealer_id
      t.integer :info_id

      t.timestamps
    end

    # jv_settings
    add_column :jv_settings,:rudy_user_name, :string
    add_column :jv_settings,:rudy_password, :string
    add_column :jv_settings, :additional_credit_amount_rate, :decimal, precision: 5, scale: 2

    # auth_tokens
    drop_table :auth_tokens
    create_table :auth_tokens do |t|
      t.references :tokenable, polymorphic: true
      t.string :token, limit: 30, null: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
