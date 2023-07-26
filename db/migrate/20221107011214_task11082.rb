class Task11082 < ActiveRecord::Migration[5.2]
  def change
    add_column :project_managers, :dealer_type, :integer, limit: 1, null: false, default: 1, after: :project_manager_name
  end
end
