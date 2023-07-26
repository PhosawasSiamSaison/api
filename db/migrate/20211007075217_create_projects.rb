class CreateProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :projects do |t|
      t.string :project_code, null: false
      t.integer :project_type, limit: 1, null: false
      t.string :project_name, null: false
      t.bigint :project_manager_id, null: false
      t.decimal :project_value, precision: 10, scale: 2
      t.decimal :project_limit, precision: 10, scale: 2, null: false
      t.decimal :delay_penalty_rate, precision: 5, scale: 2, default: 0, null: false
      t.string :project_owner, limit: 40
      t.string :start_ymd, limit: 8, null: false
      t.string :finish_ymd, limit: 8, null: false
      t.string :address, limit: 1000
      t.integer :progress, default: 0, null: false
      t.integer :status, limit: 1, default: 1, null: false
      t.string :contract_registered_ymd, limit: 8, null: false
      t.bigint :create_user_id, null: false
      t.bigint :update_user_id, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end

    create_table :project_documents do |t|
      t.bigint :project_id, null: false
      t.integer :file_type, limit: 1, null: false
      t.string :file_name, limit: 100, null: false
      t.text :comment
      t.bigint :create_user_id, null: false
      t.bigint :update_user_id, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end

    create_table :project_managers do |t|
      t.string :tax_id, limit: 13, null: false
      t.string :project_manager_code, limit: 20, null: false
      t.string :project_manager_name, limit: 50, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end

    create_table :project_phases do |t|
      t.bigint :project_id, null: false
      t.integer :phase_number, null: false
      t.string :phase_name, null: false
      t.decimal :phase_value, precision: 10, scale: 2, null: false
      t.string :start_ymd, limit: 8, null: false
      t.string :finish_ymd, limit: 8, null: false
      t.string :due_ymd, limit: 8, null: false
      t.integer :status, limit: 1, default: 1, null: false
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end
  end
end
