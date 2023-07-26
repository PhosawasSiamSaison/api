class Task8507 < ActiveRecord::Migration[5.2]
  def change
    # business_days
    drop_table :system_days
    create_table :business_days do |t|
      t.string :business_ymd, limit: 8, null: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
