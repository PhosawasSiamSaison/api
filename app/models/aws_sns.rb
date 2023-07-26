class AwsSns
  class << self
    def send_sms(sms)
      # sms_providerを記録する
      sms.aws_sns!

      result = create_sns_client.publish(
        phone_number: format_mobile_number(sms.send_to),
        message:      sms.message_body
      )

      # TODO 10383 エラーを出力すると落ちるので一旦コメントアウトへ
      # p result.inspect

      sms.done!
    rescue Exception => e
      p e
    end

    private

    def create_sns_client
      @client ||= Aws::SNS::Client.new(
        access_key_id:     JvService::Application.config.try(:aws_access_key_id),
        secret_access_key: JvService::Application.config.try(:aws_secret_access_key),
        region:            JvService::Application.config.try(:aws_region)
      )
    end

    def format_mobile_number(mobile_number)
      # 0で始まる場合は0を削除する(国際コードの連結、フロント10桁制限、日本の番号を登録できる対応)
      if mobile_number.start_with?('0')
        mobile_number = mobile_number.slice(1..-1)
      end

      # 国際コードを追加する
      JvService::Application.config.try(:country_code) + mobile_number
    end
  end
end
