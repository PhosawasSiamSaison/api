class Task9243 < ActiveRecord::Migration[5.2]
  def change
    change_column :products, :product_name, :string, limit: 20
  end
end
