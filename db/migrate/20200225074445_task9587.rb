class Task9587 < ActiveRecord::Migration[5.2]
 def up
    change_column :scoring_results, :bank_statement_value, :string, limit: 8, null: true
    change_column :scoring_results, :capital_value, :string, limit: 20, null: true
    change_column :scoring_results, :no_of_employee_value, :string, limit: 20, null: true
    change_column :scoring_results, :years_in_business_value, :string, limit: 6, null: true
  end
 
  def down
    change_column :scoring_results, :bank_statement_value, :string, limit: 6, null: false
    change_column :scoring_results, :capital_value, :decimal, precision: 10, scale: 2, null: false
    change_column :scoring_results, :no_of_employee_value, :integer, limit: 3, null: true
    change_column :scoring_results, :years_in_business_value, :integer, limit: 2, null: false
  end
end
