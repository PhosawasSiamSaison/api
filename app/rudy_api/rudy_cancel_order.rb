class RudyCancelOrder < RudyApiBase
  def initialize(order)
    @order = order
  end

  def exec
    url = switch_url(:cancel_order)

    params = {}
    params["DocID"]       = @order.order_number
    params["dealer_code"] = @order.dealer.dealer_code
    params["tax_id"]      = @order.contractor.tax_id
    params["bill_date"]   = @order.bill_date.presence
    params["site_code"]   = @order.any_site&.site_code

    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request(url, params) : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]
    rescue Exception => e
      log_error('Cancel Transaction', e)

      return "RUDY ERROR: #{JSON.parse(e.message)["items"]}"
    end

    return nil
  end

  private

  def request(url, params)
    bearer = RudyApiSetting.bearer

    if use_test_params?
      params["DocID"]       = 'RD2022010001'
      params["dealer_code"] = 'CPS0001'
      params["tax_id"]      = '5440700021408'
      params["bill_date"]   = nil
      params["site_code"]   = nil
    end

    log_start('Cancel Transaction', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Cancel Transaction', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    case @order.order_number
    when '500'
      {
        "status" => 500,
        "items" => "RUDY API ERROR"
      }
    else
      {
        "status" => 200,
        "items" => "Success"
      }
    end
  end
end
