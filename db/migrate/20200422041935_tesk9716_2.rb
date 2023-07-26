class Tesk97162 < ActiveRecord::Migration[5.2]
  def up
    add_column :orders, :rescheduled_fee_order_id, :integer, null: true, after: :rescheduled_new_order_id
    add_column :orders, :fee_order, :boolean, null: true, default: false, after: :rescheduled_at
    add_column :installments, :exempt_late_charge, :boolean, null: false, default: false, after: :rescheduled
  end

  def down
    remove_column :orders, :rescheduled_fee_order_id
    remove_column :orders, :fee_order
    remove_column :installments, :exempt_late_charge
  end
end
