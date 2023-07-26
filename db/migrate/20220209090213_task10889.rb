class Task10889 < ActiveRecord::Migration[5.2]
  def change
    create_table :mail_spools do |t|
      t.references :contractor, foreign_key: true, null: false
      t.references :contractor_user, foreign_key: true, null: false

      t.string :send_to, null: false
      t.string :subject
      t.text :mail_body
      t.integer :mail_type, limit: 1, null: false
      t.integer :send_status, limit: 1, default: 1, null: false

      t.integer  :deleted, limit: 1, null: false, default: 0
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end
  end
end
