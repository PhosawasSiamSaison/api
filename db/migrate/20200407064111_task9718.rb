class Task9718 < ActiveRecord::Migration[5.2]
  def up
    change_column :eligibilities, :create_user_id, :integer, null: true
  end
  
  def down
    change_column :eligibilities, :create_user_id, :integer, null: false
  end
end