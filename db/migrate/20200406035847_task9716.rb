class Task9716 < ActiveRecord::Migration[5.2]
  def up
    change_column :orders, :dealer_id, :integer, null: true

    add_column :orders, :rescheduled_new_order_id, :integer, null: true, after: :for_dealer_payment_id
    add_column :orders, :rescheduled_user_id, :integer, null: true, after: :rescheduled_new_order_id
    add_column :orders, :rescheduled_at, :datetime, null: true, after: :rescheduled_user_id
    add_column :installments, :rescheduled, :boolean, null: false, default: false, after: :installment_number
  end

  def down
    change_column :orders, :dealer_id, :integer, null: false
    remove_column :orders, :rescheduled_new_order_id
    remove_column :orders, :rescheduled_user_id
    remove_column :orders, :rescheduled_at
    remove_column :installments, :rescheduled
  end
end
