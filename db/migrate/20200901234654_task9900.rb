class Task9900 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :front_d_version, :string, after: :front_c_version
  end
end
