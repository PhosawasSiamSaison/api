class Task11014 < ActiveRecord::Migration[5.2]
  def change
    remove_column :project_phase_sites, :progress, :integer
  end
end
