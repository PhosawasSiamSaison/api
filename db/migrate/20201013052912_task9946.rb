class Task9946 < ActiveRecord::Migration[5.2]
  def up
    unless Product.find_by(product_key: 6)
      Product.create!(
        id: 6,
        product_key: 6,
        product_name: "Product 6",
        number_of_installments: 1,
        sort_number: 6,
        annual_interest_rate: 1.5,
        monthly_interest_rate: 0.75
      )
    end

    unless Product.find_by(product_key: 6)
      Product.create!(
        id: 7,
        product_key: 7,
        product_name: "Product 7",
        number_of_installments: 1,
        sort_number: 7,
        annual_interest_rate: 2.5,
        monthly_interest_rate: 0.83
      )
    end
  end

  def down
    Product.find(6).destroy
    Product.find(7).destroy
  end
end
