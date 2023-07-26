class Task97442 < ActiveRecord::Migration[5.2]
  def up
    change_column :orders, :product_id, :integer, null: true
  end

  def down
    change_column :orders, :product_id, :integer, null: false
  end
end
