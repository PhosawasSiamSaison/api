class RudyCreateSite < RudyApiBase
  def initialize(project_phase_site)
    @project_phase_site = project_phase_site
  end

  def exec
    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]
    rescue Exception => e
      log_error('Create Site', e)
    end
  end

  private

  def request
    url = switch_url(:create_site)

    params = if use_test_params?
      {
        "tax_no"    => "0105563009954",
        "site_name" => "Government Chiang Mai U",
        "site_code" => "GovCMU001S01",
        "address"   => "Chiang Mai",
        "shop_id"   => "202"
      }
    else
      {
        "tax_no"    => @project_phase_site.contractor.tax_id,
        "site_name" => @project_phase_site.site_name,
        "site_code" => @project_phase_site.site_code,
        "address"   => @project_phase_site.project.address,
        "shop_id"   => @project_phase_site.project.project_manager.shop_id,
      }
    end

    bearer = RudyApiSetting.bearer

    log_start('Create Site', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Create Site', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    {
      "status" => 200,
      "items" => "Success"
    }
  end
end
