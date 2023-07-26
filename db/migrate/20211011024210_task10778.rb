class Task10778 < ActiveRecord::Migration[5.2]
  def change
    add_reference :orders, :second_dealer, foreign_key: { to_table: :dealers }, after: :dealer_id

    add_column :orders, :second_dealer_amount, :decimal, precision: 5, scale: 2, default: nil,
      after: :amount_without_tax
  end
end
