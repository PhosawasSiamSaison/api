desc 'Dealerトップ画面のグラフデータの集計(運用)'
task :save_dealer_purchase_of_month, ['month'] => :environment do |task, args|
  begin
    month = args[:month]

    raise '引数を入力してください' if month.blank?
    raise '形式が不正です' if month.length != 6

    Dealer.all.each do |dealer|
      # 既存のデータを削除
      dealer.dealer_purchase_of_months.where(month: month).destroy_all

      # 日付の変換
      date = Date.strptime(month, '%Y%m')
      # 新しくデータを集計・登録する
      dealer.save_purchase_data(date)
    end

    p '完了'
  rescue Exception => e
    p e.message
  end

end
