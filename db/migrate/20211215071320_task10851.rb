class Task10851 < ActiveRecord::Migration[5.2]
  def up
    change_column :orders, :second_dealer_amount, :decimal, precision: 10, scale: 2, default: nil
  end

  def down
    change_column :orders, :second_dealer_amount, :decimal, precision: 5, scale: 2, default: nil
  end
end
