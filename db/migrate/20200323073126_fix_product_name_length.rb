class FixProductNameLength < ActiveRecord::Migration[5.2]
  def up
    change_column :products, :product_name, :string, limit: 40
  end

  def down
    change_column :products, :product_name, :string, limit: 20
  end
end
