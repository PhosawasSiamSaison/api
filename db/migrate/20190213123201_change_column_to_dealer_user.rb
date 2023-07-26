class ChangeColumnToDealerUser < ActiveRecord::Migration[5.2]
  def up
    add_column :dealer_users, :create_user_type, :string, after: :temp_password
    add_column :dealer_users, :update_user_type, :string, after: :create_user_id
    change_column :dealer_users, :create_user_id, :integer, after: :create_user_type
    change_column :dealer_users, :update_user_id, :integer, after: :update_user_type
    add_index :dealer_users, [:create_user_type, :create_user_id]
    add_index :dealer_users, [:update_user_type, :update_user_id]
  end

  def down
    remove_column :dealer_users, :create_user_type, :string, after: :temp_password
    remove_column :dealer_users, :update_user_type, :string, after: :create_user_id
    change_column :dealer_users, :create_user_id, :integer, null: false, after: :temp_password
    change_column :dealer_users, :update_user_id, :integer, null: false, after: :create_user_id
    remove_index :dealer_users, :create_user_id
    remove_index :dealer_users, :update_user_id
  end
end
