class JvMailer < ApplicationMailer
  def send_mail
    mail_spool = params[:mail_spool]

    headers['X-Priority'] = 1

    # Send Billing PDFメールの場合はここでファイルを添付する
    if mail_spool.contractor_billing_data.present?
      pdf, file_name = GenerateContractorBillingPDF.new.call(mail_spool.contractor_billing_data)

      attachments[file_name] = pdf.render
    end

    @body = mail_spool.mail_body

    mail(
      from:    mail_spool.sender,
      to:      mail_spool.email_addresses_str,
      subject: mail_spool.subject,
      template_name: 'base.text',
      bcc: ["phosawas@siamsaison.com", "thitikwan@siamsaison.com"],
      delivery_method_options: mail_spool.delivery_method_options
    )

    mail_spool.done!
  rescue => e
    if params[:mail_spool].contractor_billing_data.present?
      id = params[:mail_spool].contractor_billing_data.id

      Rails.logger.fatal "Send Billing PDF Error. contractor_billing_data_id: #{id}"
    else
      raise e
    end
  end
end
