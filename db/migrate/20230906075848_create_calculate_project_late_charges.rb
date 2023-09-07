class CreateCalculateProjectLateCharges < ActiveRecord::Migration[6.0]
  def change
    create_table :calculate_project_late_charges do |t|
      t.integer :calculate_project_and_installment_id, null: false
      t.integer :installment_id, null: false
      t.string  :payment_ymd, limit: 8, null: false
      t.string  :due_ymd, limit: 8, null: false
      t.string  :late_charge_start_ymd, limit: 8
      t.string  :calc_start_ymd, limit: 8
      t.integer :late_charge_days
      t.integer :delay_penalty_rate
      t.decimal :remaining_amount_without_late_charge, precision: 10, scale: 2, default: 0.00
      t.string :calced_amount
      t.string :calced_days
      t.decimal :original_late_charge_amount, precision: 10, scale: 2, default: 0.00
      t.decimal :calc_paid_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_late_charge_before_late_charge_start_ymd, precision: 10, scale: 2, default: 0.00
      t.decimal :calc_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_late_charge, precision: 10, scale: 2, default: 0.00

      t.timestamps
    end
  end
end
