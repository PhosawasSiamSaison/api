class Batch::InformStatement < Batch::BatchParent
  # ส่งการยืนยันจำนวนเงินที่ชำระหลังจากวันที่ปิดบัญชี
  def self.exec
    print_info "InformStatement [開始]        #{Time.zone.now}"

    begin
      # 締め日の翌日のみ実施する
      if BusinessDay.today_is(1) || BusinessDay.today_is(16)
        print_info "対象日"

        send_count = 0

        # 支払い済みでも一応送る
        PaymentDefault.where(status: %w(paid next_due), due_ymd: next_due_ymd).each do |payment|
          contractor = payment.contractor

          # 請求系のSMSの送信を止める判定
          next if contractor.stop_payment_sms

          contractor.contractor_users.sms_targets.each do |contractor_user|
            SendMessage.send_inform_statement(payment, contractor_user)
            send_count += 1

            # レート制限用
            if delay_batch_send_sms && send_count == 18
              sleep 1
              send_count = 0
            end
          end
        end
      else
        print_info "対象日ではない"
      end
    rescue Exception => e
      print_info "InformStatement [終了][異常]  #{Time.zone.now}"
      raise e
    end

    print_info "InformStatement [終了][正常]  #{Time.zone.now}"
  end

  private
  def self.next_due_ymd
    date = nil
    day = nil

    # 締め日が月末、翌月1日に実行
    if BusinessDay.today.day <= SystemSetting.closing_day
      date = BusinessDay.today
      # 月末の日付を取得
      day = date.end_of_month.day

    # 締め日が15日、16日に実行
    else
      date = BusinessDay.today.next_month
      # 翌月15日の日付を取得
      day = SystemSetting.closing_day
    end

    Date.new(date.year, date.month, day).strftime('%Y%m%d')
  end
end