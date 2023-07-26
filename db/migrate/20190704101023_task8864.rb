class Task8864 < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :change_product_status, :integer, limit: 1, null: false, default: 1, after: :input_ymd_updated_at
    add_column :orders, :is_applying_change_product, :boolean, null: false, default: false, after: :change_product_status
    add_column :orders, :applied_change_product_id, :integer, after: :is_applying_change_product
    add_column :orders, :change_product_memo, :string, limit: 200, after: :applied_change_product_id
    add_column :orders, :change_product_applied_at, :datetime, after: :change_product_memo
    add_column :orders, :change_product_applied_user_id, :integer, after: :change_product_applied_at
  end
end
