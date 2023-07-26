class AddColumnToDealerUser < ActiveRecord::Migration[5.2]
  def change
    add_column :dealer_users, :agreed_at, :datetime, after: :status

    remove_column :dealer_users, :initialize_tax_id_token, :string, limit: 30
  end
end
