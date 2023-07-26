class Batch::UpdateBusinessDayToNextDay < Batch::BatchParent
  # 業務日を１日進める
  def self.exec
    print_info "UpdateBusinessDayToNextDay [開始]        #{Time.zone.now}"

    begin
      BusinessDay.update_next_day
    rescue Exception => e
      print_info "UpdateBusinessDayToNextDay [終了][異常]  #{Time.zone.now}"
      raise e
    end
    
    print_info "UpdateBusinessDayToNextDay [終了][正常]  #{Time.zone.now}"
  end
end
