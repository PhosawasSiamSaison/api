class AddEmailToJvUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :jv_users, :email, :string, limit: 200, after: :mobile_number
  end
end
