class Batch::CreateContractorBillingZip < Batch::BatchParent
  # 締め日に請求書PDF(とそれをまとめたZIP)ファイルを作成する
  def self.exec
    print_info "CreateContractorBillingZip [開始]        #{Time.zone.now}"

    error_detected = false

    # 締め日(15 or 月末)の判定
    if BusinessDay.closing_day?
      # 今日の締め日から1ヶ月後のDue Date
      due_ymd = BusinessDay.next_due_ymd

      begin
        # Zipファイルを作成
        CreateAndUploadContractorBillingZip.new.call(due_ymd)
      rescue Exception => e
        error_detected = true
        print_info e
        print_info "CreateContractorBillingZip [終了][異常]  #{Time.zone.now}"
        # zip(pdf)作成時のエラーはスローしない
      end
    else
      print_info "今日（#{BusinessDay.today_ymd}）は締め日ではありませんでした。"
    end

    unless error_detected
      print_info "CreateContractorBillingZip [終了][正常]  #{Time.zone.now}"
    end
  end
end
