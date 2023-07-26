class RemoveLoginFailedCountFromDealerUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :dealer_users, :login_failed_count, :integer
  end
end
