# 検証用の日回しバッチ
class Batch::Daily
  def self.exec(to_ymd: BusinessDay.tomorrow_ymd)
    process_days = (Date.parse(to_ymd) - BusinessDay.today).to_i

    process_days.times.each do |i|
      Batch::UpdateOverDueStatus.exec
      Batch::UpdateNextDueOnClosingDay.exec
      Batch::CreateContractorBillingData.exec
      Batch::CreateContractorBillingZip.exec
      Batch::SavePurchaseData.exec
      Batch::UpdateBusinessDayToNextDay.exec
      Batch::SendBillingEmail.exec
      # sms and email
      Batch::InformStatement.exec
      Batch::OverDueNextDay.exec
      Batch::ReminderOnDueDate.exec
      Batch::ReminderTwoDaysBeforeDueDate.exec
      Batch::SendCanSwitch3daysAgoSms.exec
      Batch::SendCanSwitch7daysAgoSms.exec
    end
  end
end