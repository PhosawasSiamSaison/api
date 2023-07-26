class Batch::ReminderTwoDaysBeforeDueDate < Batch::BatchParent
  # 約定日の2日前に通知を送る
  def self.exec
    print_info "ReminderTwoDaysBeforeDueDate [開始]        #{Time.zone.now}"

    begin
      # 業務日の2日後を取得
      day_after_tomorrow_ymd = BusinessDay.day_after_tomorrow_ymd

      # 2日後が締め日(約定日)の場合のみ実施する
      if BusinessDay.closing_ymd?(day_after_tomorrow_ymd)
        print_info "対象日"

        send_count = 0

        PaymentDefault.next_due.where(due_ymd: day_after_tomorrow_ymd).each do |payment|
          contractor = payment.contractor

          # 請求系のSMSの送信を止める判定
          next if contractor.stop_payment_sms

          contractor.contractor_users.sms_targets.each do |contractor_user|
            SendMessage.send_reminder_two_days_before_due_date(payment, contractor_user)
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
      print_info "ReminderTwoDaysBeforeDueDate [終了][異常]  #{Time.zone.now}"
      raise e
    end

    print_info "ReminderTwoDaysBeforeDueDate [終了][正常]  #{Time.zone.now}"
  end
end
