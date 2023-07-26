class Task11059 < ActiveRecord::Migration[5.2]
  def change
    create_table :site_limit_change_applications do |t|
      t.references :project_phase_site, null: false
      t.decimal :site_limit, precision: 13, scale: 2, null: false
      t.boolean :approved, null: false, default: false

      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end

    change_column_default :project_phase_sites, :site_limit, from: nil, to: 0
  end
end
