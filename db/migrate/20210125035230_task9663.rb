class Task9663 < ActiveRecord::Migration[5.2]
  def change
    create_table :contractor_billing_data do |t|
      t.references :contractor, foreign_key: true, null: false
      t.string :th_company_name, limit: 50, null: false
      t.string :address, limit: 100, null: false
      t.string :tax_id, limit: 13, null: false
      t.string :due_ymd, limit: 8, null: false
      t.decimal :credit_limit, precision: 10, scale: 2
      t.decimal :available_balance, precision: 10, scale: 2
      t.decimal :due_amount, precision: 10, scale: 2
      t.string :cut_off_ymd, limit: 8, null: false
      t.text :installments_json
    end

    create_table :contractor_billing_zip_ymds do |t|
      t.string :due_ymd, limit: 8, null: false
    end
  end
end
