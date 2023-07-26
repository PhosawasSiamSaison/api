class Task10109 < ActiveRecord::Migration[5.2]
  def change
    drop_table :contractors_unavailable_products
    drop_table :for_dealer_payments

    remove_column :orders, :for_dealer_payment_id
  end
end
