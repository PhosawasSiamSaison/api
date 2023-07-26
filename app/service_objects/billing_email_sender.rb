class BillingEmailSender
  def call(contractor_billing_data_ids: nil, cut_off_ymd: nil)
    contractor_billing_data = ContractorBillingData.all

    if contractor_billing_data_ids.present?
      contractor_billing_data = contractor_billing_data.where(id: contractor_billing_data_ids)
    end

    if cut_off_ymd.present?
      contractor_billing_data = contractor_billing_data.where(cut_off_ymd: cut_off_ymd)
    end

    contractor_billing_data.each do |billing_data|
      begin
        SendMail.contractor_billing_pdf(billing_data)
      rescue => e
        Rails.logger.info "Send Billing PDF Error. contractor_billing_data_id: #{billing_data.id}"
        Rails.logger.info e.inspect
      end
    end
  end
end
