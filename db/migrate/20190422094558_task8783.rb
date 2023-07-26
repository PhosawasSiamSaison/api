class Task8783 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractor_users, :user_type, :integer, limit: 1, null: false, default: 0, after: :contractor_id
  end
end
