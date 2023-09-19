class CreateTransactionFeeHistories < ActiveRecord::Migration[6.0]
  def up
    create_table :transaction_fee_histories do |t|
      t.integer :dealer_id, null: false
      t.string :apply_ymd, limit: 8
      t.decimal :for_normal_rate, null: false, precision: 5, scale: 2, default: 2
      t.decimal :for_government_rate, precision: 5, scale: 2, default: 1.75, after: :for_normal_rate
      t.decimal :for_sub_dealer_rate, precision: 5, scale: 2, default: 1.5, after: :for_government_rate
      t.decimal :for_individual_rate, precision: 5, scale: 2, default: 1.5, after: :for_sub_dealer_rate
      t.text :reason
      t.integer :status, limit: 1, null: false, default: 0
      t.integer :create_user_id
      t.integer :update_user_id

      t.integer :deleted, limit: 1, null: false, default: false
      t.timestamps
      t.integer :lock_version, default: 0
    end
  end

  def down
    drop_table :transaction_fee_histories
  end
end
