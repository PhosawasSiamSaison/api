class AddNewProductsRecord < ActiveRecord::Migration[5.2]
  def up
    Product.create!(
      id: 8,
      product_key: 8,
      product_name: "ชำระเต็ม 15 วัน (0.75%)",
      switch_sms_product_name: "ชำระเต็มจำนวน 15 วัน ดอกเบี้ย 0.75%",
      number_of_installments: 1,
      sort_number: 8,
      annual_interest_rate: 0.75,
      monthly_interest_rate: 0.75,
    )

    Product.create!(
      id: 9,
      product_key: 9,
      product_name: "ชำระเต็ม 60 วัน (ดอกเบี้ย 1.64%)",
      switch_sms_product_name: "ชำระเต็มจำนวน 60 วัน ดอกเบี้ย 1.64%",
      number_of_installments: 1,
      sort_number: 9,
      annual_interest_rate: 1.64,
      monthly_interest_rate: 0.82,
    )

    Product.create!(
      id: 10,
      product_key: 10,
      product_name: "ชำระเต็ม 90 วัน (ดอกเบี้ย 2.47%)",
      switch_sms_product_name: "ชำระเต็มจำนวน 90 วัน ดอกเบี้ย 2.47%",
      number_of_installments: 1,
      sort_number: 10,
      annual_interest_rate: 2.46,
      monthly_interest_rate: 0.82,
    )
  end

  def down
    Product.find_by(product_key: 8)&.delete
    Product.find_by(product_key: 9)&.delete
    Product.find_by(product_key: 10)&.delete
  end
end
