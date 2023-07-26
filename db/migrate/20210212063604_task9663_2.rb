class Task96632 < ActiveRecord::Migration[5.2]
  def change
    change_table :contractor_billing_data do |t|
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end

    change_table :contractor_billing_zip_ymds do |t|
      t.datetime :created_at, null: true
      t.datetime :updated_at, null: true
      t.datetime :operation_updated_at, null: true
    end
  end
end
