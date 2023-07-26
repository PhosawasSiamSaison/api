class Task9036 < ActiveRecord::Migration[5.2]
  def change
    add_column :scoring_results, :dealer_id, :integer, null: false, after: :contractor_id
    add_column :scoring_results, :dealer_credit, :decimal, precision: 10, scale: 2, after: :dealer_id
  end
end
