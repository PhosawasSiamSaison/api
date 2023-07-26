class CreateScoringResults < ActiveRecord::Migration[5.2]
  def change
    create_table :scoring_results do |t|
      t.references :contractor, foreign_key: true, null: false
      t.references :scoring_class_setting, foreign_key: true, null: false

      t.decimal :limit_amount, precision: 20, scale: 2, null: false
      t.integer :class_type, limit: 1, null: false

      t.integer :financial_info_fiscal_year

      t.integer :years_in_business
      t.decimal :register_capital, precision: 20, scale: 2
      t.decimal :shareholders_equity, precision: 20, scale: 2
      t.decimal :total_revenue, precision: 20, scale: 2
      t.decimal :net_revenue, precision: 20, scale: 2
      t.decimal :current_ratio, precision: 10, scale: 2
      t.decimal :de_ratio, precision: 10, scale: 2

      t.integer :years_in_business_score
      t.integer :register_capital_score
      t.integer :shareholders_equity_score
      t.integer :total_revenue_score
      t.integer :net_revenue_score
      t.integer :current_ratio_score
      t.integer :de_ratio_score

      t.integer :total_score

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0
    end
  end
end
