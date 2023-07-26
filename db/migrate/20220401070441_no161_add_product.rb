class No161AddProduct < ActiveRecord::Migration[5.2]
  
  def up
    #新Productの導入に伴う15日商品の利子率変更
    Product.find_by(product_key: 8)&.update!(
      product_name: "ชำระเต็ม 15 วัน", 
      switch_sms_product_name: "ชำระเต็มจำนวน 15 วัน",
      annual_interest_rate: 0.00,
      monthly_interest_rate: 0.00
    )

    #新Productの導入に伴う並び順変更
    Product.find_by(product_key: 9)&.update!(sort_number: 10)
    Product.find_by(product_key: 10)&.update!(sort_number: 11)

    #新Productの導入
    Product.create!(
      id: 11,
      product_key: 11,
      product_name: "ชำระเต็ม 30 วัน (ดอกเบี้ย 1.23%)",
      switch_sms_product_name: "ชำระเต็มจำนวน 30 วัน ดอกเบี้ย 1.23%",
      number_of_installments: 1,
      sort_number: 9,
      annual_interest_rate: 1.23,
      monthly_interest_rate: 1.23,
    )
  end

  def down
    Product.find_by(product_key: 8)&.update!(
      product_name: "ชำระเต็ม 15 วัน (0.75%)", 
      switch_sms_product_name: "ชำระเต็มจำนวน 15 วัน ดอกเบี้ย 0.75%",
      annual_interest_rate: 0.75,
      monthly_interest_rate: 0.75
    )
    Product.find_by(product_key: 9)&.update!(sort_number: 9)
    Product.find_by(product_key: 10)&.update!(sort_number: 10)
    Product.find_by(product_key: 11)&.delete
  end

end
