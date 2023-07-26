class Task10204 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :verify_mode, :integer, length: 1, null: false, default: 1, after: :front_d_version
  end
end
