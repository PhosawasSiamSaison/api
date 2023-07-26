class AddTaxIdColumnToDealer < ActiveRecord::Migration[5.2]
  def up
    add_column :dealers, :tax_id, :string, limit: 13, null: false, uniquness: true, after: :id
  end

  def down
    remove_column :dealers, :tax_id, :string, limit: 13, null: false, uniquness: true, after: :id
  end
end
