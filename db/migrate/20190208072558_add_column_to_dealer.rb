class AddColumnToDealer < ActiveRecord::Migration[5.2]
  def up
    add_column :dealers, :create_user_id, :integer, after: :status
    add_column :dealers, :update_user_id, :integer, after: :create_user_id
    add_index :dealers, :dealer_code, unique: true
  end

  def down
    remove_column :dealers, :create_user_id, :integer, after: :status
    remove_column :dealers, :update_user_id, :integer, after: :create_user_id
    remove_index :dealers, :dealer_code
  end
end
