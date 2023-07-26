class Task9035 < ActiveRecord::Migration[5.2]
  def change
    drop_table :input_assets

    create_table :scoring_assets do |t|
      t.references :contractor, foreign_key: true, null: false
      t.string :year, limit: 4, null: false
      t.boolean :no_establish, null: false, default: false
      t.boolean :no_submit, null: false, default: false
      t.decimal :amount,  precision: 10, scale: 2
      t.decimal :revenue, precision: 10, scale: 2
      t.integer :update_user_id

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
    add_index :scoring_assets, [:contractor_id, :year], unique: true
  end
end
