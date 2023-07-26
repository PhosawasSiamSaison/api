class Task11036 < ActiveRecord::Migration[5.2]
  def change
    remove_column :project_manager_users, :agreed_at
  end
end
