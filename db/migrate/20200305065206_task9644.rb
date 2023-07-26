class Task9644 < ActiveRecord::Migration[5.2]
  def up
    remove_column :scoring_results, :dealer_credit

    add_column :scoring_results, :dealer_credit_term, :decimal, precision: 10, scale: 2, after: :dealer_id
    add_column :scoring_results, :dealer_credit_amount, :decimal, precision: 10, scale: 2, after: :dealer_credit_term

    change_column :scoring_results, :transaction_period_value, :decimal, precision: 10, scale: 2
    change_column :scoring_results, :transaction_overdue_value, :decimal, precision: 10, scale: 2
  end
 
  def down
    add_column :scoring_results, :dealer_credit, :decimal, precision: 10, scale: 2, after: :dealer_id

    remove_column :scoring_results, :dealer_credit_term
    remove_column :scoring_results, :dealer_credit_amount

    change_column :scoring_results, :transaction_period_value, :integer, limit: 2
    change_column :scoring_results, :transaction_overdue_value, :integer, limit: 2
  end
end
