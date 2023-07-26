desc 'Due Basis Report CSVの出力'
task export_due_basis_csv: :environment do
  include CsvModule

  # CSVを出力
  puts(bom + due_basis_data())
end
