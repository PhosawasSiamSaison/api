class Task8398 < ActiveRecord::Migration[5.2]
  def change
  	add_column :contractors, :cashback, :decimal, null: false, default: 0, after: :pool_amount
  	add_column :contractors, :status, :integer, limit: 1, null: false, default: 1, after: :cashback
  	add_column :contractors, :registered_ymd, :string, limit: 8, after: :applied_ymd
  end
end
