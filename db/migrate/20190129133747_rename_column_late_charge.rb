class RenameColumnLateCharge < ActiveRecord::Migration[5.2]
  def change
    rename_column :installments, :late_charge, :fixed_late_charge
  end
end
