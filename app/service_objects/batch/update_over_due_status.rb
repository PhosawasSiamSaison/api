class Batch::UpdateOverDueStatus < Batch::BatchParent
  # 支払い期限までに支払いが完了していないPaymentのstatusをover_dueへ更新する
  def self.exec
    print_info "UpdateOverDueStatus [開始]        #{Time.zone.now}"

    begin
      # 対象のPayment
      # 期日が今日(business_ymd)、かつステータスが next_due (支払い予定)
      Payment.where(due_ymd: BusinessDay.today_ymd, status: :next_due).each do |payment|
        payment.update_to_over_due
      end
    rescue Exception => e
      print_info "UpdateOverDueStatus [終了][異常]  #{Time.zone.now}"
      raise e
    end
    
    print_info "UpdateOverDueStatus [終了][正常]  #{Time.zone.now}"
  end
end
