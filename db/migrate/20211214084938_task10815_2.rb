class Task108152 < ActiveRecord::Migration[5.2]
  def change
    rename_column :sms_spools, :sms_to, :send_to
    rename_column :sms_spools, :sms_body, :message_body
    rename_column :sms_spools, :sms_type, :message_type
    rename_column :sms_spools, :sms_status, :send_status

    rename_column :line_spools, :line_to, :send_to
    rename_column :line_spools, :line_body, :message_body
    rename_column :line_spools, :line_type, :message_type
    rename_column :line_spools, :line_status, :send_status
  end
end
