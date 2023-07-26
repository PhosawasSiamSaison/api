class Task9967 < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :rudy_purchase_ymd, :string, limit: 8, null: true, after: :canceled_user_id
  end
end
