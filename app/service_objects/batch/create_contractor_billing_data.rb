class Batch::CreateContractorBillingData < Batch::BatchParent
  # 締め日に請求書のデータを作成する
  def self.exec
    print_info "CreateContractorBillingData [開始]        #{Time.zone.now}"

    # 締め日(15 or 月末)の判定
    if BusinessDay.closing_day?
      # 今日の締め日から1ヶ月後のDue Date
      one_month_after_closing_ymd = BusinessDay.one_month_after_closing_ymd

      # 請求が確定したPaymentから請求データを保存
      PaymentDefault.where(due_ymd: one_month_after_closing_ymd).each do |payment|
        ContractorBillingData.create_by_payment(payment, BusinessDay.today_ymd)
      end

      # 次の締め日を取得(日付更新前なので翌日を指定)
      next_due_ymd = BusinessDay.next_due_ymd(BusinessDay.tomorrow)

      # 15日商品のオーダーが追加されていた場合は作り直す
      PaymentDefault.where(due_ymd: next_due_ymd).each do |payment|
        ContractorBillingData.create_by_payment(payment ,BusinessDay.today_ymd)
      end
    else
      print_info "今日（#{BusinessDay.today_ymd}）は締め日ではありませんでした。"
    end

    print_info "CreateContractorBillingData [終了][正常]  #{Time.zone.now}"
  rescue => e
    print_info "CreateContractorBillingData [終了][異常]  #{Time.zone.now}"
    raise e
  end
end
