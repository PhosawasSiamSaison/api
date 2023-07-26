# frozen_string_literal: true

class Jv::SmsSpoolListController < ApplicationController

  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    sms_list, total_count = SmsSpool.search(params)

    render json: {
      success: true,
      sms_list: format_sms_list(sms_list),
      total_count: total_count
    }
  end

  private
  def format_sms_list(sms_list)
    sms_list.map do |sms|
      {
        id: sms.id,
        contractor: sms.contractor && {
          id: sms.contractor.id,
          tax_id: sms.contractor.tax_id,
          th_company_name: sms.contractor.th_company_name,
          en_company_name: sms.contractor.en_company_name,
          contractor_user: {
            id: sms.contractor_user_id,
            user_name: sms.contractor_user&.user_name
          }
        },
        message_type: sms.message_type_label,
        send_to: sms.send_to,
        message_body: sms.mask_message_body,
        updated_at: sms.updated_at
      }
    end
  end
end
