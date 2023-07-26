class RudyApiBase
  RES_STATUS = {
    SUCCESS: 200,
    NOT_FOUND: 404
  }

  class << self
    def paging(results, params)
      page = params[:page]
      per_page = params[:per_page]

      [
        Kaminari.paginate_array(results).page(page).per(per_page),
        results.count
      ]
    end
  end

  private
  def create_faraday_connection(host_url)
    Faraday::Connection.new(:url => host_url) do |builder|
      builder.use Faraday::Request::Multipart
      builder.use Faraday::Request::UrlEncoded  # リクエストパラメータを URL エンコードする
      builder.use Faraday::Response::Logger     # リクエストを標準出力に出力する
      builder.use Faraday::Adapter::NetHttp     # Net/HTTP をアダプターに使う
    end
  end

  def use_test_params?
    use_test_params = JvService::Application.config.try(:rudy_use_test_params)

    use_test_params.nil? || use_test_params
  end

  def rudy_host
    JvService::Application.config.try(:rudy_host)
  end

  def rudy_connection
    create_faraday_connection(rudy_host)
  end

  def switch_url(action)
    case action
    when :login
      '/v2/authen/cons'
    when :search_product
      '/v2/th/saison/list/searchproduct/'
    when :switch_payment
      '/v2/th/saison/list/switchpayment/'
    when :search_cpac_product
      '/v2/th/saison/list/productdetail/'
    when :billing_payment
      '/v2/th/saison/list/billingpayment/'
    when :update_site_limit
      '/v2/th/saison/list/updatesitelimit/'
    when :report_saison
      '/v2/th/saison/list/reportsaison/'
    when :create_site
      '/v2/th/saison/list/createSite'
    when :cancel_order
      '/v2/th/saison/list/cancelTransaction/'
    else
      raise "予期せぬ分岐: #{action}"
    end
  end

  def log_start(action, url, params, bearer)
    Rails.logger.info({
      "logtype": "RUDY-API-REQUEST",
      "action": action,
      "url": url,
      "params": params,
    }.to_json)
  end

  def log_finish(action, res)
    Rails.logger.info({
      "logtype": "RUDY-API-RESPONSE",
      "action": action,
      "response": JSON.parse(res),
    }.to_json)
  end

  def log_error(action, error)
    error = JSON.parse(error.to_s)
  rescue => e
    # パースが失敗した場合
    error = error.to_s
  ensure
    Rails.logger.info({
      "logtype": "RUDY-API-ERROR",
      "action": action,
      "error": error,
    }.to_json)
  end
end
