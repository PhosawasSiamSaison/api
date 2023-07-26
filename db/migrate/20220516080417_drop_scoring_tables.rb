class DropScoringTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :scoring_assets
    drop_table :scoring_files
    drop_table :scoring_results
  end
end
