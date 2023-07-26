class Api::ClientBase
  def initialize(host_url:)
    @conn = Faraday.new(url: host_url) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  :httpclient
    end
  end
end
