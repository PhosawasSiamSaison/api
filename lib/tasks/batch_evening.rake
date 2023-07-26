namespace :batch do
    desc '夕方処理（OverDueのSMS送信バッチ）'
    task evening: :environment do
      Rails.logger.info('[batch] evening batch started')
      Batch::OverDueNextDay.exec
      Rails.logger.info('[batch] evening batch finished')
    end
end