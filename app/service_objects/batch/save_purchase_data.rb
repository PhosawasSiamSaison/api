class Batch::SavePurchaseData < Batch::BatchParent
  # 月末にdealer毎の注文データを集計する
  def self.exec
    print_info "SavePurchaseData [開始]        #{Time.zone.now}"

    begin
      if BusinessDay.is_end_of_month?
        print_info "対象日"

        Dealer.all.each do |dealer|
          dealer.save_purchase_data
        end
      end
    rescue Exception => e
      print_info "SavePurchaseData [終了][異常]  #{Time.zone.now}"
      raise e
    end

    print_info "SavePurchaseData [終了][正常]  #{Time.zone.now}"
  end
end
