class Task10477 < ActiveRecord::Migration[5.2]
  def up
    add_column :orders, :bill_date, :string, limit: 15, null: false, default: "", after: :product_id

    remove_index :orders, name: "index_orders_on_order_number_and_dealer_id_and_uniq_check_flg"
    add_index :orders, [:order_number, :dealer_id, :bill_date, :uniq_check_flg], unique: true, name: "ix_1"
  end

  def down
    remove_index :orders, name: "ix_1"
    add_index :orders, [:order_number, :dealer_id, :uniq_check_flg], unique: true

    remove_column :orders, :bill_date
  end
end
