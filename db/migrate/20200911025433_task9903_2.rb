class Task99032 < ActiveRecord::Migration[5.2]
  def change
    rename_column :dealer_type_settings, :sms_welcome_word, :sms_servcie_name
  end
end
