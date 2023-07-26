class Task11057 < ActiveRecord::Migration[5.2]
  def change
    add_column :project_managers, :shop_id, :string, limit: 10, null: true, after: :tax_id
    remove_column :project_managers, :project_manager_code, :string
  end
end
