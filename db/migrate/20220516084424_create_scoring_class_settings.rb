class CreateScoringClassSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :scoring_class_settings do |t|
      t.integer :class_a_min, null: false
      t.integer :class_b_min, null: false
      t.integer :class_c_min, null: false
      t.decimal :class_a_limit_amount, precision: 10, scale: 2, null: false
      t.decimal :class_b_limit_amount, precision: 10, scale: 2, null: false
      t.decimal :class_c_limit_amount, precision: 10, scale: 2, null: false
      t.boolean :latest, null: false, default: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
