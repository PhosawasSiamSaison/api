class Task11063 < ActiveRecord::Migration[5.2]
  def change
    add_reference :cashback_histories, :receive_amount_history, null: true, after: :order_id
  end
end
