class Task8517 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractor_users, :agreed_at, :datetime, after: :status
  end
end
