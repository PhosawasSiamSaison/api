class Task969423 < ActiveRecord::Migration[5.2]
  def change
    create_table :available_products do |t|
      t.references :contractor, foreign_key: true, null: false
      t.integer    :category, limit: 1, null: false
      t.references :product, foreign_key: true, null: false
      t.integer    :dealer_type, limit: 1, null: false
      t.boolean    :available, null: false

      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end
    add_index :available_products, [:contractor_id, :category, :product_id, :dealer_type], name: 'ix_1', unique: true

    # Contractor
    add_column :contractors, :is_switch_unavailable, :boolean, null: false, default: false, after: :pool_amount
    remove_column :contractors, :available_cashback, :boolean
  end
end
