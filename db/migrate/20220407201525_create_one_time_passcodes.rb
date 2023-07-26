class CreateOneTimePasscodes < ActiveRecord::Migration[5.2]
  def change
    create_table :one_time_passcodes do |t|
      t.string :token, limit: 30, null: false, unique: true
      t.string :passcode
      t.datetime :expires_at, null: false
      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end
end
