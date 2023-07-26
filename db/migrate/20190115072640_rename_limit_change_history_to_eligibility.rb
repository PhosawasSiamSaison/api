class RenameLimitChangeHistoryToEligibility < ActiveRecord::Migration[5.2]
  def change
    rename_table :limit_change_histories, :eligibilities
  end
end
