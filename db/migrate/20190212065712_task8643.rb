class Task8643 < ActiveRecord::Migration[5.2]
  def change
    rename_column :system_settings, :vat_rate, :credit_limit_additional_rate
  end
end
