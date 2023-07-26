class Task9248 < ActiveRecord::Migration[5.2]
  def change
    remove_column :installments, :late_charge_start_ymd, :string
  end
end
