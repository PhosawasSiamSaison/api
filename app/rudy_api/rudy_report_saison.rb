class RudyReportSaison < RudyApiBase
  def initialize(site_codes)
    @site_codes = site_codes
  end

  def exec
    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res['status'] != RES_STATUS[:SUCCESS]

      res['items'].map { |item| [item['project_code'], item] }.to_h
    rescue Exception => e
      log_error('Report Saison', e)

      # エラー時は空のhashを返す
      {}
    end
  end

  private

  def request
    url = switch_url(:report_saison)

    # 開発時はRUDYサーバにマッチできるデータがないのでテスト用のパラメーターを使用する
    @site_codes = ['TRJ001', 'TG001'] unless Rails.env.production?

    params = { site_code: @site_codes }

    bearer = RudyApiSetting.bearer

    log_start('Report Saison', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = params.to_query
      end

    log_finish('Report Saison', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    sample_item = {
      'project_code' => 'TG001',
      'month' => '1',
      'year' => '2021',
      'customer_name' => 'nnamtestjung',
      'customer_code' => '88888',
      'champ_customer_code' => '',
      'shop_name' => 'cpac เครดิตยิ้มได้2',
      'project_name' => 'test trgigger file ',
      'project_complete_percent' => '20.0000',
      'phasename' => [
        'งานฐานราก',
        'งานฐานราก'
      ],
      'phase_complete_percent' => [
        0
      ],
      'project_type_name' => 'บ้านเดี่ยว',
      'unit_budget' => '0.00',
      'total_transactionQo' => '0',
      'total_transactionChamp' => '0',
      'status' => 'In process',
      'start_date' => '0000-00-00 00 =>00:00',
      'last_update' => '2021-01-19 11:06:31',
      'lat_lng' => '0.0,0.0',
      'total_checkin' => '0',
      'last_checkin' => nil,
      'project_images' => 'https://files.merudy.com/projects/162452202101190406293895.jpeg,https://files.merudy.com/projects/162452202101190406304668.jpeg,https://files.merudy.com/projects/162452202101190406304860.jpeg,https://files.merudy.com/projects/162452202101190406314736.jpeg',
      'latest_image_upload' => '2021-01-19 11:06:31',
      'project_start_date' => '0000-00-00 00:00:00',
      'project_end_date' => '0000-00-00 00:00:00',
      'agreement' => nil
    }

    percent_samples = ['20.0000', '55.0000', '37.0000']

    items = []
    @site_codes.each_with_index do |site_code, i|
      item = sample_item.deep_dup
      item['project_code'] = site_code
      item['project_complete_percent'] = percent_samples[i % 3]
      items << item
    end

    {
      'status' => 200,
      'items' => items
    }
  end
end
