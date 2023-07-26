class Task8575 < ActiveRecord::Migration[5.2]
  def change
    # constactors
    add_column :contractor_users, :rudy_auth_token, :string, limit: 20, after: :login_failed_count

    # dealers
    add_column :dealers, :interest_rate, :decimal, precision: 5, scale: 2, after: :dealer_name

    # payments
    change_column :payments, :total_amount, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :payments, :paid_total_amount, :decimal, precision: 10, scale: 2, null: false, default: 0.0

    # system_settings
    rename_column :system_settings, :additional_credit_amount_rate, :vat_rate
    add_column :system_settings, :rudy_response_header_text, :text, after: :vat_rate
    add_column :system_settings, :rudy_response_text, :text, after: :rudy_response_header_text
  end
end
