class RudyLogin < RudyApiBase
  def initialize(user_name, password)
    @user_name = user_name
    @password = password
  end

  def exec
    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request : mock_response

      # レスポンスのエラーチェック
      case res["status"]
      when RES_STATUS[:SUCCESS]
        true
      when RES_STATUS[:NOT_FOUND]
        false
      else
        raise res.to_json
      end
    rescue Exception => e
      log_error('Login', e)

      raise e
    end
  end

  private
  def request
    url = switch_url(:login)

    params =
      if use_test_params?
        {
          "username" => "TESTCONA",
          "password" => @password
        }
      elsif Rails.env.production?
        {
          "username" => @user_name,
          "password" => @password
        }
      end

    bearer = RudyApiSetting.bearer

    log_start('Login', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Login', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    case @password.to_s
    when '200'
      {
        "status" => 200,
        "items" => {}
      }
    when '401'
      {
        "status" => 401,
        "items" => "cannot access"
      }
    else
      {
        "status" => 404,
        "items" => "Sorry not found"
      }
    end
  end
end
