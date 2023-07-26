class Task8497 < ActiveRecord::Migration[5.2]
  def change
    drop_table :for_dealer_payments
    create_table :for_dealer_payments do |t|
      t.references :dealer, foreign_key: true
      t.integer :status, limit: 1, null: false, default: 1
      t.datetime :confirmed_at
      t.datetime :paid_at
      t.integer :confirmed_user_id
      t.integer :paid_user_id
      t.text    :comment

      t.integer  :deleted, limit: 1, default: 0, null: false
      t.timestamps
      t.integer  :lock_version, default: 0
    end
  end
end
