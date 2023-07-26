class CreateProjectPhotos < ActiveRecord::Migration[5.2]
  def change
    create_table :project_photos do |t|
      t.bigint :project_phase_id, null: false
      t.bigint :contractor_id, null: false
      t.string :file_name, limit: 100, null: false
      t.string :photo_ymd, limit: 8, null: false
      t.text :comment
      t.bigint :create_user_id, null: false
      t.bigint :update_user_id, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end
  end
end
