class AddColumnToJvUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :jv_users, :initialize_tax_id_token, :string, limit: 30
  end
end
