class Task9323 < ActiveRecord::Migration[5.2]
  def change
  	create_table :change_product_applies do |t|
      t.references :contractor, foreign_key: true
      t.string :due_ymd, limit: 8, null: false
      t.datetime :completed_at
      t.string :memo, limit: 500
      t.integer :apply_user_id
      t.integer :register_user_id

      t.timestamps
      t.integer  :lock_version, default: 0
    end

    add_column :orders, :change_product_apply_id, :integer
  end
end
