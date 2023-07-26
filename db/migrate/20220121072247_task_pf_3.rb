class TaskPf3 < ActiveRecord::Migration[5.2]
  def change
    add_column :project_phases, :phase_limit, :decimal, precision: 10, scale: 2, default: 0, after: :phase_value
  end
end
