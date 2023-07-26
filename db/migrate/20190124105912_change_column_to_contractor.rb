class ChangeColumnToContractor < ActiveRecord::Migration[5.2]
  def up
    change_column :contractors, :pool_amount, :decimal, precision: 10, scale: 2, null: false, default: 0.00
  end

  def down
    change_column :contractors, :pool_amount, :decimal, null: false, default: 0.00
  end
end
