class AddColumnSystemSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :front_pm_version, :string, after: :front_d_version
  end
end
