class CreateProjectManagerUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :project_manager_users do |t|
      t.integer :project_manager_id, null: false
      t.integer :user_type, limit: 1, null: false
      t.string :user_name, limit: 20, null: false
      t.string :full_name, limit:40, null: false
      t.string :mobile_number, limit: 11
      t.string :email, limit: 200
      t.datetime :agreed_at
      t.string :password_digest, null: false
      t.string :temp_password, limit: 16
      t.bigint :create_user_id, null: false
      t.bigint :update_user_id, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end
  end
end
