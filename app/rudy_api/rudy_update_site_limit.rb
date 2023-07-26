class RudyUpdateSiteLimit < RudyApiBase
  def initialize(order)
    @order = order
  end

  def exec
    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]
    rescue Exception => e
      log_error('Update Site Limit', e)

      # エラーになっても例外エラーは出さない(ロールバックはしない)
    end
  end

  private

  def request
    url = switch_url(:update_site_limit)

    site = @order.site
    dealer = @order.dealer

    params = {
      "site_code"        => site.site_code,
      "new_site_limit"   => site.site_credit_limit.to_f,
      "dealer_code"      => dealer.dealer_code,
      "new_site_balance" => site.available_balance,
    }

    bearer = RudyApiSetting.bearer

    log_start('Update Site Limit', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Update Site Limit', res.body)

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
