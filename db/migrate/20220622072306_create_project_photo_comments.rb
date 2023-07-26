class CreateProjectPhotoComments < ActiveRecord::Migration[5.2]
  def change
    create_table :project_photo_comments do |t|
      t.string :file_name, limit: 100, null: false
      t.text :comment
      t.bigint :create_user_id, null: false
      t.bigint :update_user_id, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end

    add_index :project_photo_comments, :file_name, unique: true
  end
end
