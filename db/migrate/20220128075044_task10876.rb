class Task10876 < ActiveRecord::Migration[5.2]
  def change
    create_table :delay_penalty_rate_update_histories do |t|
      t.references :contractor, foreign_key: true, null: false
      t.references :update_user, foreign_key: { to_table: :jv_users }, null: true

      t.integer :old_rate, limit: 1, null: false
      t.integer :new_rate, limit: 1, null: false

      t.integer  :deleted, limit: 1, null: false, default: 0
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end
  end
end
