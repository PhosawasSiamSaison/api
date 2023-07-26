class AddColumnToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :latest_credit_limit, :decimal, precision: 10, scale: 2, after: :owner_email
  end
end
