desc 'Dealer/Dealer Type Limit履歴CSVの出力'
task export_credit_limit_history: :environment do
  include CsvModule

  # CSVを出力
  puts(bom + credit_limit_history(nil, nil))
end
