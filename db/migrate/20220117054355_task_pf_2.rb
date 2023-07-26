class TaskPf2 < ActiveRecord::Migration[5.2]
  def change
    add_column :project_phase_sites, :refund_amount, :decimal, precision: 10, scale: 2, default: 0, after: :site_limit
    add_column :project_phase_sites, :paid_total_amount, :decimal, precision: 10, scale: 2, default: 0, after: :site_limit
    add_column :project_phases, :paid_up_ymd, :string, limit: 8, default: nil, after: :due_ymd
    change_column_default :projects, :delay_penalty_rate, from: 0.0, to: nil
  end
end
