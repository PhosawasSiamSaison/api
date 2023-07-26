class No181AddProductAndChangeName < ActiveRecord::Migration[5.2]
  def up
    Product.create!(
      id: 12,
      product_key: 12,
      product_name: "ชำระเต็ม 90 วัน (ดอกเบี้ย 3.69%)",
      switch_sms_product_name: "ชำระเต็มจำนวน 90 วัน ดอกเบี้ย 1.23%/เดือน",
      number_of_installments: 1,
      sort_number: 12,
      annual_interest_rate: 3.69,
      monthly_interest_rate: 1.23,
    )
    Product.find_by(product_key: 4)&.update!(product_name: "ชำระเต็ม 60 วัน (ดอกเบี้ย 2.46%)")
  end

  def down
    Product.find_by(product_key: 12)&.delete
    Product.find_by(product_key: 4)&.update!(product_name: "ชำระเต็ม 60 วัน")
  end
end
