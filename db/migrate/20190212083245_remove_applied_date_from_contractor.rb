class RemoveAppliedDateFromContractor < ActiveRecord::Migration[5.2]
  def change
    remove_column :contractors, :applied_date, :datetime
  end
end
