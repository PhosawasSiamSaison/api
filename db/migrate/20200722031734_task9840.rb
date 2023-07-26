class Task9840 < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractor_users, :agreed_at, :datetime
  end
end
