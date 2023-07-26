class Task9470 < ActiveRecord::Migration[5.2]
  def change
    add_column :dealers, :dealer_type, :integer, limit: 1, null: false, default: 1 , after: :area_id
    add_column :contractors, :sub_dealer, :boolean, null: false, default: false, after: :main_dealer_id
    add_column :contractors, :dealer_type, :integer, limit: 1, null: false, default: 1 , after: :sub_dealer
    add_column :contractors, :available_cashback, :boolean, null: false, default: true, after: :dealer_type
  end
end
