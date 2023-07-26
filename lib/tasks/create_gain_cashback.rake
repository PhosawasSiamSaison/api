desc '獲得キャッシュバックの作成(運用)'
require 'csv'

task :create_gain_cashback, ['csv_file'] => :environment do |task, args|
  csv_file = args[:csv_file]
  
  if csv_file.blank?
    error_msg
    p "引数を入力してください"
    next
  end

  if !File.file?(csv_file)
    error_msg
    p "インプットファイル: #{csv_file} が見つかりませんでした"
    next
  end

  CSV.foreach(csv_file, headers: true).with_index(1) do |row, lineno|
    p "行番号: #{lineno} Start"
    
    tax_id   = row['tax_id']
    amount   = row['amount'].to_f
    # notesの値が未設定の場合、Earned Cashbackが登録される。
    notes    = row['notes'].blank? ? nil : row['notes']
    order_id = row['order_id']

    contractor = Contractor.qualified.find_by(tax_id: tax_id)

    if contractor.blank?
      error_msg
      p "tax_id: #{tax_id} のContractorは見つかりませんでした"
      next
    end

    if amount <= 0
      error_msg
      p "amountが不正です"
      next
    end

    if order_id.present? && contractor.orders.find_by(id: order_id).blank?
      error_msg
      p "order_idが不正です"
      next
    end

    begin
      contractor.create_gain_cashback_history(amount, BusinessDay.today_ymd, order_id, notes: notes)
    rescue Exception => e
      error_msg
      p e
      next
    end
    p "行番号: #{lineno} End"
  end

  p '完了'
end

def error_msg
  p "!!! エラー !!!"
end