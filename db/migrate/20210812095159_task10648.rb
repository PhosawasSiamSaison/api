class Task10648 < ActiveRecord::Migration[5.2]
  def change
    create_table :receive_amount_details do |t|
      t.references :receive_amount_history, foreign_key: true, null: false

      t.string :order_number
      t.string :dealer_name, limit: 50
      t.integer :dealer_type, limit: 1
      t.string :tax_id, limit: 15
      t.string :th_company_name, limit: 50
      t.string :en_company_name, limit: 50
      t.string :bill_date, limit: 15
      t.string :site_code, limit: 15
      t.string :site_name
      t.string :product_name, limit: 40
      t.integer :installment_number, limit: 1
      t.string :due_ymd,         limit: 8
      t.string :input_ymd,       limit: 8
      t.datetime :switched_date
      t.datetime :rescheduled_date
      t.string :repayment_ymd, limit: 8
      t.decimal :principal,   precision: 10, scale: 2
      t.decimal :interest,    precision: 10, scale: 2
      t.decimal :late_charge, precision: 10, scale: 2
      t.decimal :paid_principal,   precision: 10, scale: 2
      t.decimal :paid_interest,    precision: 10, scale: 2
      t.decimal :paid_late_charge, precision: 10, scale: 2
      t.decimal :total_principal,   precision: 10, scale: 2
      t.decimal :total_interest,    precision: 10, scale: 2
      t.decimal :total_late_charge, precision: 10, scale: 2
      t.decimal :exceeded_occurred_amount, precision: 10, scale: 2
      t.string :exceeded_occurred_ymd, limit: 8
      t.decimal :exceeded_paid_amount, precision: 10, scale: 2
      t.decimal :cashback_paid_amount, precision: 10, scale: 2
      t.decimal :cashback_occurred_amount, precision: 10, scale: 2
      t.decimal :waive_late_charge, precision: 10, scale: 2

      # 冗長カラム
      t.references :contractor,  foreign_key: true, null: false
      t.references :payment,     foreign_key: true, null: true
      t.references :order,       foreign_key: true, null: true
      t.references :installment, foreign_key: true, null: true
      t.references :dealer,      foreign_key: true, null: true

      t.integer  :deleted, limit: 1, null: false, default: 0
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end
  end
end
