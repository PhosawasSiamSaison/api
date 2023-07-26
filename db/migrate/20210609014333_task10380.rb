class Task10380 < ActiveRecord::Migration[5.2]
  def change
    create_table :adjust_repayment_histories do |t|
      t.references :contractor, foreign_key: true, null: false
      t.references :installment, foreign_key: true, null: false

      t.bigint :created_user_id
      t.string :business_ymd, limit: 8, null: false
      t.decimal :to_exceeded_amount, precision: 10, scale: 2, null: false

      t.text :before_detail_json

      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end
  end
end
