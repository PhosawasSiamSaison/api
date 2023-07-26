class Task8861 < ActiveRecord::Migration[5.2]
  def change
    add_column :contractor_users, :rudy_passcode, :string, limit: 10, after: :login_failed_count
    add_column :contractor_users, :rudy_passcode_created_at, :datetime, after: :rudy_passcode
  end
end
