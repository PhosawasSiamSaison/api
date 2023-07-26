class Task8658 < ActiveRecord::Migration[5.2]
  def change
    add_column :payments, :paid_exceeded, :decimal, precision: 10, scale: 2, null: false, default: 0, after: :paid_total_amount
    add_column :payments, :paid_cashback, :decimal, precision: 10, scale: 2, null: false, default: 0, after: :paid_exceeded
  end
end
