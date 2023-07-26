class Task8912 < ActiveRecord::Migration[5.2]
  def change
    remove_column :eligibilities, :auto_scored, :boolean

    change_column :eligibilities, :create_user_id, :integer

    create_table :input_assets do |t|
      t.references :contractor, foreign_key: true, null: false
      t.string :year, limit: 4, null: false
      t.decimal :amount,  precision: 10, scale: 2, null: false
      t.decimal :revenue, precision: 10, scale: 2, null: false
      t.integer :update_user_id

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
    add_index :input_assets, [:contractor_id, :year], unique: true

    create_table :scoring_results do |t|
      t.references :contractor, foreign_key: true, null: false

      t.decimal :limit_amount, precision: 10, scale: 2, null: false
      t.integer :class_type, limit: 1, null: false

      t.boolean :bank_statement_value, null: false
      t.integer :bank_statement_score, limit: 1, null: false

      t.decimal :capital_value, precision: 10, scale: 2, null: false
      t.integer :capital_score, limit: 1, null: false

      t.integer :no_of_employee_value, limit: 3, null: false
      t.integer :no_of_employee_score, limit: 1, null: false

      t.integer :years_in_business_value, limit: 2, null: false
      t.integer :years_in_business_score, limit: 1, null: false

      t.integer :business_performance_score, limit: 1

      t.integer :ceo_age_value, limit: 2, null: false
      t.integer :ceo_age_score, limit: 1, null: false

      t.integer :transaction_period_value, limit: 2, null: false
      t.integer :transaction_period_score, limit: 1, null: false

      t.decimal :transaction_amount_value, precision: 10, scale: 2, null: false
      t.integer :transaction_amount_score, limit: 1, null: false

      t.integer :transaction_overdue_value, limit: 2, null: false
      t.integer :transaction_overdue_score, limit: 1, null: false

      t.integer :rudy_no_of_project,    limit: 2, null: false 
      t.integer :rudy_valuer_and_type,  limit: 2, null: false 
      t.integer :rudy_contact_per_site, limit: 2, null: false 
      t.integer :rudy_no_of_work,       limit: 2, null: false 
      t.integer :rudy_total_score,      limit: 2, null: false

      t.string  :rudy_ranking,      limit: 1, null: false 
      t.integer :rudy_class_score,      limit: 1, null: false

      t.integer :total_score, limit: 2, null: false

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
  end
end
