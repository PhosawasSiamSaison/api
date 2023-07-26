class Task8876 < ActiveRecord::Migration[5.2]
  def change
    create_table :dealer_purchase_of_months do |t|
      t.references :dealer, foreign_key: true
      t.string :month, limit: 6
      t.decimal :purchase_amount, precision: 10, scale: 2, null: false, default: 0
      t.integer :order_count, null: false, default: 0

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
    add_index :dealer_purchase_of_months, [:dealer_id, :month], unique: true
  end
end
