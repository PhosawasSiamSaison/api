class Task11104 < ActiveRecord::Migration[5.2]
  def up
    Product.create!(
      id: 13,
      product_key: 13,
      product_name: "ชำระเต็ม 90 วัน (ดอกเบี้ย 0%)",
      switch_sms_product_name: "ชำระเต็มจำนวน 90 วัน ดอกเบี้ย 0%",
      number_of_installments: 1,
      sort_number: 13,
      annual_interest_rate: 0,
      monthly_interest_rate: 0,
    )

    # ソート番号の更新
    Product.update_sort_numbers([1,4,5,13,2,3,6,7,8,11,9,10,12])

    GlobalAvailableSetting.insert_category_data(insert_data)
  end

  def down
    Product.find_by(product_key: 13)&.delete

    # ソート番号の更新
    Product.update_sort_numbers([1,4,5,2,3,6,7,8,11,9,10,12])

    GlobalAvailableSetting.where(product_id: 13).delete_all
  end

  private
    def insert_data
      {
        normal:     category_data,
        sub_dealer: category_data,
        individual: category_data,
        government: category_data
      }
    end

    def category_data
      {
        purchase: dealer_data(["transformer"]),
        switch: dealer_data([])
      }
    end

    def dealer_data(available_dealer_types)
      data = {}
      ApplicationRecord.dealer_types.keys.each {|dealer_type|
        # GlobalSettingでtrueにするdealer_type
        available = available_dealer_types.include?(dealer_type)

        data[dealer_type.to_sym] = { 13 => available }
      }

      data
    end
end
