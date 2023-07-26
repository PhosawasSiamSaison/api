class Tesk88642 < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :change_product_before_due_ymd, :string, limit: 8, after: :change_product_memo
    add_column :orders, :product_changed_at, :datetime, after: :change_product_applied_at
    add_column :orders, :product_changed_user_id, :integer, after: :product_changed_at
  end
end
