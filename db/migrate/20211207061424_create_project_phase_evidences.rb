class CreateProjectPhaseEvidences < ActiveRecord::Migration[5.2]
  def change
    create_table :project_phase_evidences do |t|
      t.bigint :project_phase_id, null: false
      t.string :evidence_number, limit: 10, null: false, index: { unique: true }
      t.text :comment
      t.datetime :checked_at
      t.bigint :checked_user_id
      t.integer :deleted, limit: 1, default: 0
      t.timestamps
      t.datetime :operation_updated_at
      t.integer :lock_version, default: 0, null: false
    end
  end
end
