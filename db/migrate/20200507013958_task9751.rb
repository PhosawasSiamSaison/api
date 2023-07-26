class Task9751 < ActiveRecord::Migration[5.2]
  def up
    change_column :orders, :order_type, :string, limit: 30
  end

  def down
    change_column :orders, :order_type, :integer, limit: 1
  end
end
