# frozen_string_literal: true

class Jv::EmailHistoryController < ApplicationController

  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    mail_spools, total_count = MailSpool.search(params)

    render json: {
      success: true,
      email_history: mail_spools.map { |mail_spool|
        {
          id: mail_spool.id,
          contractor: mail_spool.contractor && {
            id: mail_spool.contractor.id,
            tax_id: mail_spool.contractor.tax_id,
            th_company_name: mail_spool.contractor.th_company_name,
            en_company_name: mail_spool.contractor.en_company_name,
          },
          contractor_users: mail_spool.send_email_addresses.map {|send_email_address|
            {
              send_to:   send_email_address.send_to,
              user_name: send_email_address.contractor_user&.user_name,
            }
          },
          subject:         mail_spool.subject,
          mail_type_label: mail_spool.mail_type_label[:label],
          mail_body:       mail_spool.mask_mail_body,
          send_status:     mail_spool.send_status_label,
          updated_at:      mail_spool.updated_at
        }
      },
      total_count: total_count
    }
  end
end
