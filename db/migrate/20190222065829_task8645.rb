class Task8645 < ActiveRecord::Migration[5.2]
  def change
    remove_column :jv_users, :status, :integer
    remove_column :dealer_users, :status, :integer
    remove_column :contractor_users, :status, :integer
    remove_column :installments, :fixed_late_charge, :decimal
  end
end
