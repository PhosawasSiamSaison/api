class CredenApiBase
  private

  def create_faraday_connection(host_url)
    Faraday::Connection.new(:url => host_url) do |builder|
      builder.use Faraday::Response::Logger     # リクエストを標準出力に出力する
      builder.use Faraday::Adapter::NetHttp     # Net/HTTP をアダプターに使う
    end
  end

  def creden_host
    JvService::Application.config.try(:creden_host)
  end

  def creden_connection
    create_faraday_connection(creden_host)
  end

  def api_key
    JvService::Application.config.try(:creden_api_key)
  end

  def switch_path(action)
    case action
    when :get_data_detail
      '/get_data_detail'
    else
      raise "予期せぬ分岐: #{action}"
    end
  end

  def log_start(action, url, params)
    Rails.logger.info({
      "logtype": "CREDEN-API-REQUEST",
      "action": action,
      "url": url,
      "params": params,
    }.to_json)
  end

  def log_finish(action, res)
    Rails.logger.info({
      "logtype": "CREDEN-API-RESPONSE",
      "action": action,
      "response": JSON.parse(res),
    }.to_json)
  end

  def log_error(action, error)
    # エラーのときのerrorはJSON形式でない。
    Rails.logger.info({
      "logtype": "CREDEN-API-ERROR",
      "action": action,
      "error": error,
    }.to_json)
  end
end
