class Task104772 < ActiveRecord::Migration[5.2]
  def up
    remove_index :orders, name: "ix_1"
    add_index :orders, [:order_number, :dealer_id, :bill_date, :site_id, :uniq_check_flg], unique: true, name: "ix_1"
  end

  def down
    remove_index :orders, name: "ix_1"
    add_index :orders, [:order_number, :dealer_id, :bill_date, :uniq_check_flg], unique: true, name: "ix_1"
  end
end
