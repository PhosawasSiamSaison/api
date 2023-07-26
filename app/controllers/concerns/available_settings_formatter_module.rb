module AvailableSettingsFormatterModule
  def format_available_settings(contractor = nil, detail_view: false, contractor_type: nil)
    available_settings = AvailableProduct.available_settings(contractor, contractor_type)

    # 詳細画面ではDealerTypeLimitが設定されているDealerTypeのみを表示する
    filtered_dealer_types = contractor.enabled_limit_dealer_types if detail_view

    # Purchase
    purchase_dealer_types =
      format_dealer_types(available_settings[:purchase][:dealer_type], filtered_dealer_types)

    # Switch
    is_switch_unavailable = available_settings[:is_switch_unavailable]

    # 詳細画面かつSwitch利用不可は空の配列を返す
    switch_dealer_types =
      if detail_view && is_switch_unavailable 
        []
      else
        format_dealer_types(available_settings[:switch][:dealer_type], filtered_dealer_types)
      end

    # Cashback
    cashback_dealer_types = available_settings[:cashback][:dealer_type].map {|dealer_type, settings|
      next if filtered_dealer_types && !filtered_dealer_types.include?(dealer_type)

      {
        dealer_type_label: AvailableProduct.dealer_type_label(dealer_type)
      }.merge(settings)
    }.compact

    return {
      no_dealer_limit_settings: available_settings[:no_dealer_limit_settings],
      purchase_use_global:      available_settings[:purchase_use_global],
      switch_use_global:        available_settings[:switch_use_global],
      cashback_use_global:      available_settings[:cashback_use_global],
      is_switch_unavailable:    is_switch_unavailable,

      purchase: {
        products: available_settings[:purchase][:products],
        dealer_types: purchase_dealer_types,
      },
      switch: {
        products: available_settings[:switch][:products],
        dealer_types: switch_dealer_types,
      },
      cashback: {
        dealer_types: cashback_dealer_types,
      }
    }
  end

  private
  def format_dealer_types(settings, filtered_dealer_types)
    settings.map {|dealer_type, value|
      next if filtered_dealer_types && !filtered_dealer_types.include?(dealer_type)

      {
        dealer_type_label: AvailableProduct.dealer_type_label(dealer_type),
        product_key: value[:product_key]
      }
    }.compact
  end
end