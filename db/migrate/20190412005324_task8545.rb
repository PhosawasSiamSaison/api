class Task8545 < ActiveRecord::Migration[5.2]
  def change
    add_column :for_dealer_payments, :reference_no, :string, limit: 20, after: :comment
    add_column :for_dealer_payments, :transfer_ymd, :string, limit:  8, after: :reference_no

    remove_column :orders, :transaction_fee, :decimal
  end
end
