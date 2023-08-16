class Batch::CreateContractorBillingData < Batch::BatchParent
  # 締め日に請求書のデータを作成する
  def self.exec
    print_info "CreateContractorBillingData [開始]        #{Time.zone.now}"

    # ตัดสินวันที่ปิด (วันที่ 15 หรือสิ้นเดือน)
    if BusinessDay.closing_day?
      # # วันครบกำหนดหนึ่งเดือนนับจากวันที่ปิดวันนี้
      # one_month_after_closing_ymd = BusinessDay.one_month_after_closing_ymd
      # pp "::: one_month_after_closing_ymd = #{one_month_after_closing_ymd}"

      # # บันทึกข้อมูลการเรียกเก็บเงินจากการชำระเงินเมื่อการเรียกเก็บเงินได้รับการยืนยัน
      # PaymentDefault.where(due_ymd: one_month_after_closing_ymd).each do |payment|
      #   ContractorBillingData.create_by_payment(payment, BusinessDay.today_ymd)
      # end

      # รับวันที่ปิดถัดไป (ระบุวันถัดไปเพราะวันที่ไม่ได้อัพเดท)
      next_due_ymd = BusinessDay.next_due_ymd(BusinessDay.tomorrow)
      pp "::: next_due_ymd = #{next_due_ymd}"

      # หากมีการเพิ่มคำสั่งซื้อสำหรับผลิตภัณฑ์ที่ 15 ให้สร้างขึ้นใหม่
      PaymentDefault.where(due_ymd: next_due_ymd, status: %W(next_due)).each do |payment|
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
