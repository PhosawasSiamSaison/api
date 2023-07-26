def global_available_settings_test_data
  {
    normal:     category_data(:normal),
    sub_dealer: category_data(:sub_dealer),
    individual: category_data(:individual),
    government: category_data(:government)
  }
end

private
  def category_data(contractor_type)
    # { category: { dealer_type: { product_key: available_flg } } }
    {
      purchase: ApplicationRecord.dealer_types.keys.map{|key| [key.to_sym, product_data(:purchase, :cbm)]}.to_h,
      switch:   ApplicationRecord.dealer_types.keys.map{|key| [key.to_sym, product_data(:switch, :cbm)]}.to_h,
      cashback: {
        cbm:          true,
        global_house: true,
        transformer:  true,
        cpac:        false,
        q_mix:       false,
        solution:    false,
        b2b:         false,
        nam:         false,
        bigth:       false,
        permsin:     false,
        scgp:        false,
        rakmao:      false,
        cotto:       false,
        d_gov:       false,
      }
    }
  end

  def product_data(category, dealer_type)
    Product.all.map {|product|
      [product.product_key, true]
    }.to_h
  end
