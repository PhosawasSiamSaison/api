class FifthMigration < ActiveRecord::Migration[5.2]
  def change
    # system_days
    create_table :system_days do |t|
      t.string :system_ymd, limit: 8, null: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    # cashback_histories
    remove_column :cashback_histories, :repayment_id
    change_column :cashback_histories, :quantity, :decimal, precision: 10, scale: 2
    change_column :cashback_histories, :total, :decimal, precision: 10, scale: 2

    # contractor_users
    rename_column :contractor_users, :sms_auth_token, :initialize_tax_id_token
    add_column :contractor_users, :create_user_id, :integer, after: :temp_password
    add_column :contractor_users, :update_user_id, :integer, after: :create_user_id

    # contractors
    change_column :contractors, :tax_id, :string, limit: 15, null: false,  after: :main_dealer_id
    change_column :contractors, :main_dealer_id, :integer, after: :tax_id
    change_column :contractors, :cashback, :decimal, precision: 10, scale: 2
    change_column :contractors, :latest_credit_limit, :decimal, precision: 10, scale: 2, after: :cashback
    add_column    :contractors, :approval_user_id, :integer, after: :authorized_person_line_id
    add_column    :contractors, :update_user_id, :integer, after: :approval_user_id

    # dealer_users
    rename_column :dealer_users, :sms_auth_token, :initialize_tax_id_token
    add_column :dealer_users, :create_user_id, :integer, null: false, after: :temp_password
    add_column :dealer_users, :update_user_id, :integer, null: false, after: :create_user_id
    change_column :dealer_users, :status, :integer, limit: 1, null: false, default: 1

    # dealer
    change_column :dealers, :status, :integer, limit: 1, null: false, default: 1

    # eligibilities
    change_column :eligibilities, :limit_amount, :decimal, precision: 10, scale: 2, null: false
    change_column :eligibilities, :comment, :string, limit: 100, null: false
    add_column    :eligibilities, :create_user_id, :integer, null: false, after: :comment

    # installments
    drop_table :installments
    create_table :installments do |t|
      t.integer :order_id, null: false
      t.integer :installment_number, limit: 1, null: false
      t.string  :due_ymd, limit: 8, null: false
      t.string  :paid_up_ymd, limit: 8
      t.decimal :principal, precision: 10, scale: 2
      t.decimal :interest, precision: 10, scale: 2
      t.decimal :late_charge, precision: 10, scale: 2
      t.decimal :paid_principal, precision: 10, scale: 2
      t.decimal :paid_interest, precision: 10, scale: 2
      t.decimal :paid_late_charge, precision: 10, scale: 2

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    # jv_users
    rename_column :jv_users, :sms_auth_token, :initialize_tax_id_token
    add_column :jv_users, :create_user_id, :integer, after: :status
    add_column :jv_users, :update_user_id, :integer, after: :create_user_id
    change_column :jv_users, :status, :integer, limit: 1, null: false, default: 1

    # orders
    drop_table :orders
    create_table :orders do |t|
      t.string  :order_number, null: false
      t.integer :contractor_id, null: false
      t.integer :dealer_id, null: false
      t.integer :product_id, null: false
      t.integer :for_dealer_payment_id
      t.integer :installment_count, limit: 1, null: false
      t.string  :purchase_ymd, limit: 8, null: false
      t.decimal :purchase_amount, precision: 10, scale: 2, null: false
      t.decimal :transaction_fee, precision: 5, scale: 2
      t.string  :paid_up_ymd, limit: 8
      t.string  :input_ymd, limit: 8
      t.datetime :input_ymd_updated_at
      t.integer :order_user_id, null: false

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    # system_settings
    drop_table :jv_settings
    create_table :system_settings do |t|
      t.text     :bank_account_info
      t.string   :mobile_number
      t.string   :rudy_user_name
      t.string   :rudy_password
      t.decimal  :additional_credit_amount_rate, precision: 5, scale: 2

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    # products
    create_table :products do |t|
      t.integer :product_key, limit: 1
      t.string  :product_name, limit: 10
      t.integer :number_of_installments, limit: 2
      t.decimal :annual_interest_rate, precision: 5, scale: 2
      t.decimal :monthly_interest_rate, precision: 5, scale: 2

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    # for_dealer_payments
    create_table :for_dealer_payments do |t|
      t.integer :dealer_id, null: false
      t.decimal :total_sales_amount, precision: 10, scale: 2, null: false
      t.decimal :total_transaction_fee, precision: 10, scale: 2, null: false
      t.decimal :total_payment_amount, precision: 10, scale: 2, null: false
      t.string  :paid_ymd, limit: 8, null: false
      t.string  :comment, limit: 100, null: false
      t.integer :create_user_id, null: false

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    # confirm_works
    create_table :confirm_works do |t|
      t.integer :contractor_id, null: false
      t.string  :confirm_ymd, limit: 8, null: false
      t.integer :create_user_id, null: false

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    # receive_amount_histories
    create_table :receive_amount_histories do |t|
      t.integer :contractor_id, null: false
      t.string :receive_ymd, limit: 8, null: false
      t.decimal :receive_amount, precision: 10, scale: 2, null: false
      t.string :comment, limit: 8, null: false
      t.integer :create_user_id, null: false

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
  end
end
