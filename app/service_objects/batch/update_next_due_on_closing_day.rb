class Batch::UpdateNextDueOnClosingDay < Batch::BatchParent
  # 締め日にPaymentのステータスを next_due (支払い予定) に更新する
  def self.exec
    print_info "UpdateNextDueOnClosingDay [開始]        #{Time.zone.now}"

    # 締め日(15 or 月末)の判定
    if BusinessDay.closing_day?
      begin
        # กำหนดการใหม่
        Order.not_input_ymd.payable_orders.each do |order|
          order.update_due_ymd
        end

        # 今日の締め日から1ヶ月後までの締め日
        # (15日商品も対象にするので範囲で指定する)
        due_ymd_range = BusinessDay.today_ymd..BusinessDay.next_due_ymd(BusinessDay.tomorrow)

        # 1ヶ月以内の約定日のPaymentのstatus(not_due_yet)を next_dueへ更新
        Payment.where(due_ymd: due_ymd_range).not_due_yet.each do |payment|
          # Input Dateのない15日商品がある場合はnot_due_yetにするので判定を入れる
          payment.update_to_next_due if payment.any_orders_input_ymd_present?
        end
      rescue Exception => e
        print_info "UpdateNextDueOnClosingDay [終了][異常]  #{Time.zone.now}"
        raise e
      end
    else
      print_info "今日（#{BusinessDay.today_ymd}）は締め日ではありませんでした。"
    end

    print_info "UpdateNextDueOnClosingDay [終了][正常]  #{Time.zone.now}"
  end
end
