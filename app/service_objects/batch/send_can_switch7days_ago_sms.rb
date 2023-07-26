class Batch::SendCanSwitch7daysAgoSms < Batch::BatchParent
  # 約定日の１週間前にローン変更申請可能通知を送る
  def self.exec
    print_info "SendCanSwitch7daysAgoSms [開始]        #{Time.zone.now}"

    begin
      # 実行の判定
      exec_batch =
        BusinessDay.today.day == 8 || # 15日締め日の１週間前
        BusinessDay.today == BusinessDay.today.end_of_month - 1.week # 月末の締め日の１週間前

      if !exec_batch
        print_info "対象日ではない"
        return
      end

      # 直近の約定日を取得
      due_ymd = BusinessDay.next_due_ymd

      send_count = 0

      PaymentDefault.next_due.where(due_ymd: due_ymd).each do |payment|
        contractor = payment.contractor

        # 請求系のSMSの送信を止める判定
        next if contractor.stop_payment_sms

        # ローン変更可能な商品がなければ送らない
        next unless payment.has_can_apply_change_product_order?

        # 本文に挿入するデータ
        switch_message_body_data = SwitchMessageBodyData.new.call(payment)

        contractor.contractor_users.sms_targets.each do |contractor_user|
          # DealerType毎にSMSを送信
          switch_message_body_data.each do |body_data|
            SendMessage.send_can_switch_7days_ago(body_data, contractor_user)
            send_count += 1

            # レート制限用
            if delay_batch_send_sms && send_count == 18
              sleep 1
              send_count = 0
            end
          end
        end
      end
    rescue Exception => e
      print_info "SendCanSwitch7daysAgoSms [終了][異常]  #{Time.zone.now}"
      raise e
    end

    print_info "SendCanSwitch7daysAgoSms [終了][正常]  #{Time.zone.now}"
  end
end
