class Task11083 < ActiveRecord::Migration[5.2]
  def change
    create_table :password_reset_failed_user_names do |t|
      t.string :user_name, null: false
      t.boolean :locked, null: false, default: false

      t.timestamps
      t.datetime :operation_updated_at
    end
  end
end
