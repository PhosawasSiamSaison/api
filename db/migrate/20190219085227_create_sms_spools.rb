class CreateSmsSpools < ActiveRecord::Migration[5.2]
  def change
    create_table :sms_spools do |t|
      t.string :sms_to, limit: 255, null: false
      t.text :sms_body
      t.integer :sms_type, limit: 1, null: false
      t.integer :sms_status, limit: 1, null: false, default: 1
      t.integer :deleted, limit: 1, null: false, default: 0
      t.integer :lock_version


      t.timestamps
    end
  end
end
