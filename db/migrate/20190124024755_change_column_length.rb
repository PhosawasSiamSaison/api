class ChangeColumnLength < ActiveRecord::Migration[5.2]
  def change
    # dealers
    change_column :dealers, :dealer_name, :string, limit: 50

    # system_settings
    remove_column :system_settings, :bank_account_info
    remove_column :system_settings, :mobile_number
    remove_column :system_settings, :rudy_user_name
    remove_column :system_settings, :rudy_password
    remove_column :system_settings, :rudy_response_header_text
    remove_column :system_settings, :rudy_response_text

    # rudy_settings
    create_table :rudy_api_settings do |t|
      t.string :user_name
      t.string :password
      t.text   :response_header_text
      t.text   :response_text

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
