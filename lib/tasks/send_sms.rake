desc 'SMSの再送'
task send_sms: :environment do
  cli = HighLine.new

  ids_str = cli.ask("sms_spoolsのidを指定してください。複数のidはカンマ区切りで入力できます。(例: 1,2,3)")

  ids = []
  begin
    ids = ids_str.split(',')
  rescue Exception => e
    puts "入力された値の形式が不正です。実行を中止します。"
    puts e
    puts "送信件数: 0件"
    next
  end

  begin
    ids = SmsSpool.find(ids).map(&:id)
  rescue Exception => e
    puts "指定したidは見つかりませんでした。"
    puts e
    puts "送信件数: 0件"
    next
  end

  sms_spools = []

  ActiveRecord::Base.transaction do
    sms_spools = SmsSpool.lock.where(id: ids).order(:id)
    sms_spools.update_all(send_status: :sending)
  end

  begin
    sms_spools.each do |sms|
      SendSmsJob.perform_later(sms)

      sms.done!
      puts "id: #{sms.id} 送信完了"
    end

    puts "送信件数: #{sms_spools.count}件"
  rescue Exception => e
    puts e
    puts "予期せぬエラーが発生"
  end
end
