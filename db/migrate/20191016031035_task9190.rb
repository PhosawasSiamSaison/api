class Task9190 < ActiveRecord::Migration[5.2]
  def change
    create_table :contractors_unavailable_products do |t|
      t.references :contractor, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :create_user_id

      t.timestamps
      t.integer  :lock_version, default: 0
    end
    add_index :contractors_unavailable_products, [:contractor_id, :product_id], unique: true, name: 'ix_1'

    Product.create!(
      id: 4,
      product_key: 4,
      product_name: "Product 4",
      number_of_installments: 1,
      annual_interest_rate: 2.46,
      monthly_interest_rate: 1.23
    )
  end
end
