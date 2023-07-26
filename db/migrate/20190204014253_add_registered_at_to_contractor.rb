class AddRegisteredAtToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :registered_at, :datetime, after: :applied_date
  end
end
