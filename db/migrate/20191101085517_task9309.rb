class Task9309 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :stop_payment_sms, :boolean, null: false, default: false, after: :check_payment
  end
end
