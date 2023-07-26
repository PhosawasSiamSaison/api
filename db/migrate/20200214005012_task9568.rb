class Task9568 < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :amount_without_tax, :decimal, precision: 10, scale: 2, after: :purchase_amount
    add_column :orders, :order_type, :integer, limit: 1, after: :site_id
  end
end
