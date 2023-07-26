class Task9765 < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :region, :string, limit: 50, null: true, after: :change_product_apply_id
  end
end
