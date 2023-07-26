class ChangeColumnToJvUser < ActiveRecord::Migration[5.2]
  def up
    change_column :jv_users, :mobile_number, :string, limit: 11, null: true
  end

  def down
    change_column :jv_users, :mobile_number, :string, limit: 11, null: false
  end
end
