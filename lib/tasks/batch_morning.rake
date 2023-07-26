namespace :batch do
    desc '朝処理（請求/リマインダー/Switch可能通知）のSMS送信バッチ）'
    task morning: :environment do
      Rails.logger.info('[batch] morning batch started')
      Batch::InformStatement.exec
      Batch::ReminderTwoDaysBeforeDueDate.exec
      Batch::ReminderOnDueDate.exec
      Batch::SendCanSwitch3daysAgoSms.exec
      Batch::SendCanSwitch7daysAgoSms.exec
      Rails.logger.info('[batch] morning batch finished')
    end
end