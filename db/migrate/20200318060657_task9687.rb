class Task9687 < ActiveRecord::Migration[5.2]
  def change
    change_column :contractor_users, :title_division, :string, limit: 40
  end
end
