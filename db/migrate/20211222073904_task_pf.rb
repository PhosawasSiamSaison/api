class TaskPf < ActiveRecord::Migration[5.2]
  def up
    add_reference :orders, :project_phase_site, foreign_key: true, after: :site_id
  end

  def down
    remove_reference :orders, :project_phase_site
  end
end
