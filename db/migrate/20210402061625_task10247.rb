class Task10247 < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :is_project, :boolean, null: false, default: 0, after: :dealer_id
  end
end
