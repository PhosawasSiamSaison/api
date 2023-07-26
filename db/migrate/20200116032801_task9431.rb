class Task9431 < ActiveRecord::Migration[5.2]
  def up
    create_table :sites do |t|
      t.references :contractor, foreign_key: true
      t.string     :site_code, limit: 15, null: false
      t.string     :site_name, null: false
      t.decimal    :site_credit_limit, precision: 10, scale: 2, null: false
      t.boolean    :closed, null: false, default: 0
      t.integer    :create_user_id, null: false
      t.integer    :deleted, limit: 1, null: false, default: 0

      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end

    add_column :orders, :site_id, :integer, after: :dealer_id

    change_column :orders, :change_product_apply_id, :integer, after: :change_product_applied_user_id
    change_column :orders, :order_user_id, :integer, null: true
  end
 
  def down
    drop_table :sites

    remove_column :orders, :site_id

    change_column :orders, :change_product_apply_id, :integer
    change_column :orders, :order_user_id, :integer, null: false
  end
end
