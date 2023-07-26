class Task8396 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :applied_ymd, :string, limit: 8, null: false, after: :application_number
  end
end
