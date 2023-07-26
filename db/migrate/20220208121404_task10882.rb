class Task10882 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractor_users, :email, :string, limit: 200, after: :title_division
  end
end
