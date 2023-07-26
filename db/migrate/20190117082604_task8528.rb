class Task8528 < ActiveRecord::Migration[5.2]
  def change
    drop_table :payments
    create_table :payments do |t|
      t.integer :contractor_id, null: false
      t.string :due_ymd, limit: 8, null: false
      t.string :paid_up_ymd, limit: 8
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.decimal :paid_total_amount, precision: 10, scale: 2, null: false
      t.integer :status, limit: 1, null: false

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end

    remove_column :orders, :payment_id
  end
end
