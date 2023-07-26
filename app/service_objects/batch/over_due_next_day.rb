class Batch::OverDueNextDay < Batch::BatchParent
  # 約定日の次の日と10日後に遅延したPaymentに通知を送る
  # 支払いがなければ毎月送る
  def self.exec
    print_info "OverDueNextDay [開始]        #{Time.zone.now}"

    begin
      # 締め日の1日後, 10日後が対象
      if BusinessDay.today_is(1) || BusinessDay.today_is(10) || BusinessDay.today_is(16) || BusinessDay.today_is(25)
        print_info "対象日"

        send_count = 0

        # 約定日が月末のover_dueのpaymentを持つContractorを取得
        Contractor.has_over_due_payment_contractors.each do |contractor|
          # エビデンスのチェックの必要がないContractorが対象
          next if contractor.check_payment

          # 請求系のSMSの送信を止める判定
          next if contractor.stop_payment_sms

          contractor.contractor_users.sms_targets.each do |contractor_user|
            SendMessage.send_over_due_next_day(contractor_user)
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
      print_info "OverDueNextDay [終了][異常]  #{Time.zone.now}"
      raise e
    end

    print_info "OverDueNextDay [終了][正常]  #{Time.zone.now}"
  end
end