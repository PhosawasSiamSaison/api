# frozen_string_literal: true

module RudyApiUtil
  def create_order(contractor_user, order_number, product, dealer, purchase_ymd, amount)
    contractor = contractor_user.contractor

    contractor_user.update!(rudy_auth_token: 'hoge')

    # 注文1
    params = {
      tax_id: contractor.tax_id,
      order_number: order_number,
      product_id: product.product_key,
      dealer_code: dealer.dealer_code,
      purchase_date: purchase_ymd,
      amount: amount,
      auth_token: 'hoge',
    }

    post rudy_create_order_path, params: params, headers: headers

    raise if res[:result] != "OK"
  end

  def set_input_date(contractor, order_number, dealer, input_ymd)
    # 配送
    params = {
      tax_id: contractor.tax_id,
      order_number: order_number,
      dealer_code: dealer.dealer_code,
      input_date: input_ymd
    }
    post rudy_set_order_input_date_path, params: params, headers: headers
    raise if res[:result] != "OK"
  end

  private
  def headers
    bearer_key = JvService::Application.config.try(:rudy_api_auth_key)
    {
      'Authorization': "Bearer #{bearer_key}"
    }
  end

  def demo_token_headers
    bearer_key = JvService::Application.config.try(:rudy_demo_api_auth_key)
    {
      'Authorization': "Bearer #{bearer_key}"
    }
  end
end
