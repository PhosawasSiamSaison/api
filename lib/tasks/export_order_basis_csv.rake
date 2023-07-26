desc 'Order Basis Report CSVの出力'
task export_order_basis_csv: :environment do
  include CsvModule

  # CSVを出力
  puts(bom + order_basis_data())
end
