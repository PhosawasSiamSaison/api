class Task10228 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :sms_provider, :integer, length: 1, null: false, default: 2, after: :verify_mode
    add_column :sms_spools, :sms_provider, :integer, length: 1, null: true, after: :sms_status
  end
end
