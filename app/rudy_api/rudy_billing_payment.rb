class RudyBillingPayment < RudyApiBase
  def initialize(order)
    @order = order
  end

  def exec
    url = switch_url(:billing_payment)

    params = {}
    params["DocID"]       = @order.order_number
    params["dealer_code"] = @order.dealer.dealer_code
    params["tax_id"]      = @order.contractor.tax_id
    params["bill_date"]   = @order.bill_date if @order.bill_date.present?
    params["site_code"]   = @order.any_site.site_code if @order.any_site.present?

    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request(url, params) : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]
    rescue Exception => e
      log_error('Billing Payment', e)

      # エラーになっても例外エラーは出さない(消し込みのロールバックはしない)
    end
  end

  private

  def request(url, params)
    bearer = RudyApiSetting.bearer

    log_start('Billing Payment', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Billing Payment', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    case RudyApiSetting.user_name
    when '404'
      {
        "status" => 404,
        "items" => "Sorry not found"
      }
    else
      {
        "status" => 200,
        "items" => "Success"
      }
    end
  end
end
