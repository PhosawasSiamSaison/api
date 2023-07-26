class ThaiBulkSms
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'base64'

  MockResponse = Struct.new(:code, :read_body)
  END_POINT = "https://api-v2.thaibulksms.com/sms"
  SENDER_NAME = "SIAMSAISON"

  class << self
    def send_sms(sms)
      # sms_providerを記録する
      sms.thai_bulk_sms!

      # セットアップ
      http, request = setup_request(END_POINT)
      set_header(request)
      set_body(request, sms)

      # リクエストの実行
      response = exec_request(http, request, sms)
      body = parse_response(response)

      # レスポンスの処理
      case response.code
      when '200', '201'
        if Rails.env.development?
          puts response
          puts body
        end

        # Success
        Rails.logger.info "Success send ThaiBulkSMS. sms_spools.id: #{sms.id}, status code: #{response.code}"

        sms.done!
      else
        Rails.logger.error "Failed send ThaiBulkSMS. sms_spools.id: #{sms.id}, status code: #{response.code}"
        Rails.logger.info body.inspect
      end
    end

    private
    def setup_request(endpoint)
      url = URI(endpoint)

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      [http, Net::HTTP::Post.new(url)]
    end

    def set_header(request)
      request["Accept"] = 'application/json'
      request["Content-Type"] = 'application/x-www-form-urlencoded'
      request["Authorization"] = gen_authorization
    end

    def set_body(request, sms)
      request.set_form_data({
        'msisdn' => format_mobile_number(sms.send_to),
        'message' => sms.message_body,
        'sender' => SENDER_NAME,
        'shorten_url' => true,
      })
    end

    def gen_authorization
      api_key = JvService::Application.config.try(:thai_bulk_sms_api_key)
      api_secret = JvService::Application.config.try(:thai_bulk_sms_api_secret)

      # 改行コードがあるとnet/httpでエラーになるので入れない
      credentials = Base64.strict_encode64("#{api_key}:#{api_secret}")

      "Basic #{credentials}"
    end

    def exec_request(http, request, sms)
      if use_mock_response?
        puts sms.inspect

        MockResponse.new('400', "{}")
      else
        http.request(request)
      end
    end

    def parse_response(res)
      begin
        body = JSON.parse(res.read_body)
      rescue => e
        Rails.logger.error e
        Rails.logger.info "response parse error"
      end

      body
    end

    def format_mobile_number(mobile_number)
      # タイの番号の場合はそのまま返す
      return mobile_number if mobile_number.start_with?('0')

      # それ以外は国際コードを追加する
      JvService::Application.config.try(:country_code) + mobile_number
    end

    def use_mock_response?
      JvService::Application.config.try(:thai_bulk_sms_use_mock_response) || false
    end
  end
end
