class CreateProjectPhaseSites < ActiveRecord::Migration[5.2]
  def change
    create_table :project_phase_sites do |t|
      t.bigint :project_phase_id, null: false
      t.bigint :contractor_id, null: false
      t.string :site_code, null: false
      t.string :site_name, null: false
      t.decimal :phase_limit, precision: 10, scale: 2, null: false
      t.decimal :site_limit, precision: 10, scale: 2, null: false
      t.integer :progress, default: 0, null: false
      t.integer :status, limit: 4, default: 1, null: false
      t.bigint :create_user_id, null: false
      t.bigint :update_user_id, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end
  end
end
