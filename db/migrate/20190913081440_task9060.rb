class Task9060 < ActiveRecord::Migration[5.2]
  def change
    create_table :exemption_late_charges do |t|
      t.references :installment, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0

      t.integer  :deleted, limit: 1, default: false, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end

    add_column :receive_amount_histories, :exemption_late_charge, :decimal, precision: 10, scale: 2, after: :receive_amount

    add_column :contractors, :exemption_late_charge_count, :integer, limit: 2, null: false, default: 0, after: :status
  end
end
