class Task9359 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors_unavailable_products, :action_type, :integer, limit: 1, after: :product_id

    remove_index :contractors_unavailable_products, column: [:contractor_id, :product_id], unique: true, name: 'ix_1'

    add_index :contractors_unavailable_products, [:contractor_id, :product_id, :action_type], unique: true, name: 'ix_1'
  end
end
