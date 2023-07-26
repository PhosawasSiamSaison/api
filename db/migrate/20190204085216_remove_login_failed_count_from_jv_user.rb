class RemoveLoginFailedCountFromJvUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :jv_users, :login_failed_count, :integer
  end
end
