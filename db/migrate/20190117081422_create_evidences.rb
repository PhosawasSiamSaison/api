class CreateEvidences < ActiveRecord::Migration[5.2]
  def change
    create_table :evidences do |t|
      t.references :contractor, null: false
      t.references :contractor_user, null: false
      t.references :active_storage_blob, null: false, index: { unique: true }
      t.string :evidence_number, null: false, index: { unique: true }
      t.text :comment
      t.datetime  :checked_at
      t.integer :checked_user_id

      t.timestamps
    end
  end
end
