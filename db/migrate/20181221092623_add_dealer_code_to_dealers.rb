class AddDealerCodeToDealers < ActiveRecord::Migration[5.2]
  def change
    add_column :dealers, :dealer_code, :string, limit: 20, null: false, after: :area_id
  end
end
