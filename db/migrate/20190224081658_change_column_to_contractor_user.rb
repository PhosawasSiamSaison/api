class ChangeColumnToContractorUser < ActiveRecord::Migration[5.2]
  def up
    add_column :contractor_users, :create_user_type, :string, after: :temp_password
    add_column :contractor_users, :update_user_type, :string, after: :create_user_id
    add_index :contractor_users, [:create_user_type, :create_user_id]
    add_index :contractor_users, [:update_user_type, :update_user_id]
  end

  def down
    remove_column :contractor_users, :create_user_type, :string, after: :temp_password
    remove_column :contractor_users, :update_user_type, :string, after: :create_user_id
    remove_index :contractor_users, :create_user_id
    remove_index :contractor_users, :update_user_id
  end
end
