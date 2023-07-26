class CreateCalculatePaymentAndInstallments < ActiveRecord::Migration[6.0]
  def change
    create_table :calculate_payment_and_installments do |t|
      t.integer :payment_id, null: false
      t.integer :installment_id, null: false
      t.string  :business_ymd, limit: 8, null: false
      t.string  :payment_ymd, limit: 8, null: false
      t.string  :due_ymd, limit: 8, null: false
      t.decimal :input_amount, precision: 10, scale: 2, default: 0.00
      t.decimal :total_exceeded, precision: 10, scale: 2, default: 0.00
      t.decimal :total_cashback, precision: 10, scale: 2, default: 0.00
      t.decimal :subtract_exceeded, precision: 10, scale: 2, default: 0.00
      t.decimal :subtract_cashback, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :after_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :payment_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :after_exceeded_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :after_cashback_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :after_input_amount_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_exceeded_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_cashback_remaining_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :after_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :after_exceeded_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :after_cashback_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :after_input_amount_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_exceeded_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_cashback_remaining_interest, precision: 10, scale: 2, default: 0.00
      t.decimal :remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :after_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :after_input_amount_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :after_exceeded_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :after_cashback_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_exceeded_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_cashback_remaining_principal, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_total_exceeded, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_total_cashback, precision: 10, scale: 2, default: 0.00
      t.decimal :paid_exceeded_and_cashback_amount, precision: 10, scale: 2, default: 0.00
      t.decimal :gain_exceeded_amount, precision: 10, scale: 2, default: 0.00
      t.decimal :gain_cashback_amount, precision: 10, scale: 2, default: 0.00
      t.boolean :is_exemption_late_charge, default: false
      t.decimal :exemption_late_charge, precision: 10, scale: 2, default: 0.00
      t.decimal :total_exemption_late_charge, precision: 10, scale: 2, default: 0.00

      t.timestamps
    end
  end
end
