namespace :batch do
    desc '日次処理（夜間バッチ）'
    task :daily, ['exec_count'] => :environment do |task, args|
      args.with_defaults(exec_count: '1')
      args[:exec_count].to_i.times do
        Rails.logger.info('[batch] daily batch started')
        Batch::UpdateOverDueStatus.exec
        Batch::UpdateNextDueOnClosingDay.exec
        Batch::CreateContractorBillingData.exec
        Batch::CreateContractorBillingZip.exec
        Batch::SavePurchaseData.exec
        Batch::UpdateBusinessDayToNextDay.exec
        Batch::SendBillingEmail.exec # 日付更新後に実行
        Rails.logger.info('[batch] daily batch finished')
      end
    end
  end