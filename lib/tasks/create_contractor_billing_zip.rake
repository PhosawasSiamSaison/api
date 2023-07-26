desc '請求書のzipファイルの生成'
task :create_contractor_billing_zip, ['due_ymd'] => :environment do |task, args|
  due_ymd = args[:due_ymd]

  if due_ymd.length != 8
    print '失敗：'
    puts '引数の日付が不正です'
    next
  end

  # 既存のレコードを削除する
  record = ContractorBillingZipYmd.find_by(due_ymd: due_ymd)
  if record.present?
    record.delete
  end

  # Zipファイルを作成
  CreateAndUploadContractorBillingZip.new.call(due_ymd)

  puts '請求書Zipファイルを作成が完了しました。'

rescue => e
  print '失敗：'
  puts e
end
