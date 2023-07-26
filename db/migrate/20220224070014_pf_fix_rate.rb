class PfFixRate < ActiveRecord::Migration[5.2]
  def up
    change_column :projects, :delay_penalty_rate, :integer, limit: 1, null: false
  end

  def down
    change_column :projects, :delay_penalty_rate, :decimal, precision: 5, scale: 2, null: false
  end
end
