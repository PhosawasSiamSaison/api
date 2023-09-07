class CreateCalculateProjectAndInstallments < ActiveRecord::Migration[6.0]
  def change
    create_table :calculate_project_and_installments do |t|
      t.integer :installment_id
      t.string  :business_ymd, limit: 8
      t.string  :payment_ymd, limit: 8
      t.string  :due_ymd, limit: 8
      t.decimal :input_amount, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :after_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :payment_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :after_input_amount_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :after_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :after_input_amount_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :after_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :after_input_amount_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_total_amount, precision: 10, scale: 2, default: 0.00
      t.decimal :refund_amount, precision: 10, scale: 2, default: 0.00
      t.boolean :is_exemption_late_charge, default: false
      t.decimal :exemption_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :total_exemption_late_charge, precision: 10, scale: 2, default: 0.00

      t.timestamps
    end
  end
end
