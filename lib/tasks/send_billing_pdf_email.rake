desc 'Email#8のcontractor_billing_pdfを実行する(引数はcontractor_billing_dataレコードのids)'
task :send_billing_pdf_email, ['contractor_billing_data_id'] =>  :environment do |task, args|
  begin
    id = args[:contractor_billing_data_id]

    BillingEmailSender.new.call(contractor_billing_data_ids: [id])

    p '完了'
  rescue Exception => e
    p e.message
  end

end
