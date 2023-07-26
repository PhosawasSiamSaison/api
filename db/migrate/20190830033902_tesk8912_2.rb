class Tesk89122 < ActiveRecord::Migration[5.2]
  def change
    create_table :scoring_comments do |t|
      t.references :contractor, foreign_key: true, null: false
      t.string :comment, limit: 1000, null: false
      t.integer :create_user_id, null: false

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
  end
end
