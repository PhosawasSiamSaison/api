class Task9678 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :front_jv_version, :string, after: :id
    add_column :system_settings, :front_c_version, :string, after: :front_jv_version
  end
end
