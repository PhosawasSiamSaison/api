desc 'Order List CSVの出力'
task export_order_list_csv: :environment do
  include CsvModule

  orders = Order.all

  # CSVを出力
  puts(bom + order_list_data(orders))
end
