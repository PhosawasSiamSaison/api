class Task9304 < ActiveRecord::Migration[5.2]
  def change
    rename_column :contractor_users, :initialize_tax_id_token, :initialize_token
  end
end
