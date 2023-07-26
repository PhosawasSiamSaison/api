class Task89123 < ActiveRecord::Migration[5.2]
  def change
    create_table :scoring_files do |t|
      t.references :contractor, foreign_key: true, null: false
      t.integer :file_type, limit: 1, null: false
      t.string  :file_name, limit: 100, null: false
      t.string  :ymd, limit: 8
      t.integer :create_user_id, null: false
      t.string  :remark, limit: 500

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
  end
end
