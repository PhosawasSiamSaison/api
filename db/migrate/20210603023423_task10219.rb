class Task10219 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :is_downloading_csv, :boolean, null: false, default: false, after: :sms_provider
  end
end
