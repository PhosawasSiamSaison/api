class Task9903 < ActiveRecord::Migration[5.2]
  def change
    create_table :dealer_type_settings do |t|
      t.integer    :dealer_type, limit: 1, null: false
      t.string     :dealer_type_code, limit: 40, null: false
      t.string     :sms_contact_info, limit: 150, null: false
      t.string     :sms_welcome_word, limit: 150, null: false

      t.integer    :deleted, limit: 1, null: false, default: 0
      t.timestamps
      t.datetime   :operation_updated_at
      t.integer    :lock_version, default: 0
    end
    add_index :dealer_type_settings, :dealer_type, name: 'ix_1', unique: true
  end
end
