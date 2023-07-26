class SendSmsJob < ApplicationJob
  queue_as :default
  # TODO:エラーが発生するケースを調べてリトライ制御の導入を検討する
  # retry_on(*exceptions, wait: 3.seconds, attempts: 5, queue: nil, priority: nil)

  def perform(sms)
    sms = Marshal.load(sms) if sms.instance_of?(String)

    # システム設定で使用するSMSを切り替える
    case SystemSetting.sms_provider
    when 'thai_bulk_sms'
      ThaiBulkSms.send_sms(sms)
    when 'aws_sns'
      AwsSns.send_sms(sms)
    else
      raise(UnexpectedCase, "sms_provider: #{SystemSetting.sms_provider}")
    end
  end
end
