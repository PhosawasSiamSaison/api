class Task10367 < ActiveRecord::Migration[5.2]
  def change
    add_column :installments, :used_exceeded, :decimal, precision: 10, scale: 2, null: false, default: 0, after: :paid_late_charge
    add_column :installments, :used_cashback, :decimal, precision: 10, scale: 2, null: false, default: 0, after: :used_exceeded
  end
end
