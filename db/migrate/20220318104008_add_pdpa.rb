class AddPdpa < ActiveRecord::Migration[5.2]
  def change
    create_table :pdpa_versions do |t|
      t.integer :version, limit: 1, null: false, default: 1
      t.string :file_url, null: false

      t.integer  :deleted, limit: 1, null: false, default: 0
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end

    add_index :pdpa_versions, :version, unique: true, name: "ix_1"

    create_table :contractor_user_pdpa_versions do |t|
      t.references :contractor_user, foreign_key: true, null: false
      t.references :pdpa_version, foreign_key: true, null: false

      t.boolean :agreed, null: false, default: true

      t.integer  :deleted, limit: 1, null: false, default: 0
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end

    add_index :contractor_user_pdpa_versions, [:contractor_user_id, :pdpa_version_id], unique: true, name: "ix_1"

    add_column :system_settings, :require_pdpa_ymd, :string, null: false, default: '20220601', after: :sms_provider
  end
end
