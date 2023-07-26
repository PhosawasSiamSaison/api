class Task8544 < ActiveRecord::Migration[5.2]
  def change
    remove_column :for_dealer_payments, :comment, :text
    add_column :for_dealer_payments, :comment, :text, null: false, after: :status
  end
end
