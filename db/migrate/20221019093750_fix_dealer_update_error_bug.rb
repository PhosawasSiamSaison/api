class FixDealerUpdateErrorBug < ActiveRecord::Migration[5.2]
  def change
    change_column_null :dealers, :for_individual_rate, from: false, to: true
  end
end
