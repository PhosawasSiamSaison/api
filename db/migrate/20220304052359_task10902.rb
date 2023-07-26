class Task10902 < ActiveRecord::Migration[5.2]
  def change
    add_index :contractor_billing_data, [:contractor_id, :due_ymd], unique: true
  end
end
