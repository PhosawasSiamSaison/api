class Task8529 < ActiveRecord::Migration[5.2]
  def change
    add_column :installments, :payment_id, :integer, after: :order_id

    change_column :installments, :principal, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :installments, :interest, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :installments, :late_charge, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :installments, :paid_principal, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :installments, :paid_interest, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :installments, :paid_late_charge, :decimal, precision: 10, scale: 2, null: false, default: 0.0
  end
end
