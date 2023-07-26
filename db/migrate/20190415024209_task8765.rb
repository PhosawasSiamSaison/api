class Task8765 < ActiveRecord::Migration[5.2]
  def change
    add_column :dealers, :bank_account, :string, limit: 1000, after: :dealer_name
    add_column :dealers, :address, :string, limit: 1000, after: :bank_account
  end
end
