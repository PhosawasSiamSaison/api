class Batch::SendBillingEmail < Batch::BatchParent
  # ContractorUserにBillingのPDFをメールで送信する
  def self.exec
    begin
      print_info "SendBillingEmail [開始]        #{Time.zone.now}"

      # 締め日の翌日のみ実施する
      if BusinessDay.today_is(1) || BusinessDay.today_is(16)
        BillingEmailSender.new.call(cut_off_ymd: BusinessDay.yesterday_ymd)
      else
        print_info "対象日ではない"
      end

      print_info "SendBillingEmail [終了][正常]  #{Time.zone.now}"
    rescue Exception => e
      # エラーになってもバッチ処理は継続する
      Rails.logger.fatal e
      print_info "SendBillingEmail [終了][異常]  #{Time.zone.now}"
    end
  end
end
