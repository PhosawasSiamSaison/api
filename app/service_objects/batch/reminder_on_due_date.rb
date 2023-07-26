class Batch::ReminderOnDueDate < Batch::BatchParent
  # 約定日の当日に通知を送る
  def self.exec
    print_info "ReminderOnDueDate [開始]        #{Time.zone.now}"

    begin
      # 締め日(約定日)の場合のみ実施する
      if BusinessDay.closing_day?
        print_info "対象日"

        send_count = 0

        PaymentDefault.next_due.where(due_ymd: BusinessDay.today_ymd).each do |payment|
          contractor = payment.contractor

          # 請求系のSMSの送信を止める判定
          next if contractor.stop_payment_sms

          contractor.contractor_users.sms_targets.each do |contractor_user|
            SendMessage.send_reminder_on_due_date(payment, contractor_user)
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
      print_info "ReminderOnDueDate [終了][異常]  #{Time.zone.now}"
      raise e
    end

    print_info "ReminderOnDueDate [終了][正常]  #{Time.zone.now}"
  end
end