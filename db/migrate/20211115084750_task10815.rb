class Task10815 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractor_users, :line_user_id, :string, default: nil, after: :line_id
    add_column :contractor_users, :line_nonce, :string, default: nil, after: :line_user_id

    create_table :line_spools do |t|
      t.references :contractor, foreign_key: true, null: false
      t.references :contractor_user, foreign_key: true, null: false

      t.string :line_to, null: false
      t.text :line_body
      t.integer :line_type, limit: 1, null: false
      t.integer :line_status, limit: 1, null: false, default: 1

      t.integer  :deleted, limit: 1, null: false, default: 0
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end
  end
end
