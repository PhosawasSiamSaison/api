class Task9856 < ActiveRecord::Migration[5.2]
  def change
    add_column :jv_users, :system_admin, :boolean, null: false, default: false, after: :user_type
  end
end
