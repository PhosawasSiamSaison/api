class No190IncreaseMaximumLimits < ActiveRecord::Migration[5.2]
  def up
    change_column :eligibilities, :limit_amount, :decimal, precision: 13, scale: 2, null: false
    change_column :dealer_type_limits, :limit_amount, :decimal, precision: 13, scale: 2, null: false
    change_column :dealer_limits, :limit_amount, :decimal, precision: 13, scale: 2, null: false
    change_column :sites, :site_credit_limit, :decimal, precision: 13, scale: 2, null: false
    change_column :contractor_billing_data, :credit_limit, :decimal, precision: 13, scale: 2
    change_column :contractor_billing_data, :available_balance, :decimal, precision: 13, scale: 2
    change_column :contractor_billing_data, :due_amount, :decimal, precision: 13, scale: 2
  end

  def down
    change_column :eligibilities, :limit_amount, :decimal, precision: 10, scale: 2, null: false
    change_column :dealer_type_limits, :limit_amount, :decimal, precision: 10, scale: 2, null: false
    change_column :dealer_limits, :limit_amount, :decimal, precision: 10, scale: 2, null: false
    change_column :sites, :site_credit_limit, :decimal, precision: 10, scale: 2, null: false
    change_column :contractor_billing_data, :credit_limit, :decimal, precision: 10, scale: 2
    change_column :contractor_billing_data, :available_balance, :decimal, precision: 10, scale: 2
    change_column :contractor_billing_data, :due_amount, :decimal, precision: 10, scale: 2
  end
end
