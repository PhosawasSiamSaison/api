class AddColumnToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :canceled_at, :datetime, after: :order_user_id

    add_column :orders, :canceled_user_id, :integer, after: :canceled_at
  end
end
