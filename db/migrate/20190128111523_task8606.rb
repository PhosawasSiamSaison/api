class Task8606 < ActiveRecord::Migration[5.2]
  def change
    add_column :installments, :late_charge_start_ymd, :string, limit: 8, after: :paid_up_ymd
  end
end
