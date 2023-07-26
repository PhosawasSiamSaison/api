class Task8620 < ActiveRecord::Migration[5.2]
  def change
    create_table :installment_histories do |t|
      t.integer :installment_id, null: :false

      t.string  :from_ymd, null: :false
      t.string  :to_ymd,   null: :false, default: '99991231'

      t.decimal :paid_principal,   precision: 10, scale: 2, null: false
      t.decimal :paid_interest,    precision: 10, scale: 2, null: false
      t.decimal :paid_late_charge, precision: 10, scale: 2, null: false

      t.string  :late_charge_start_ymd, limit: 8

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
    add_index :installment_histories, [:installment_id, :from_ymd], unique: true
    add_index :installment_histories, [:installment_id, :to_ymd], unique: true
  end
end
