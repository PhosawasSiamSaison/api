# frozen_string_literal: true

class Jv::LineSpoolListController < ApplicationController

  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    line_list, total_count = LineSpool.search(params)

    render json: {
      success: true,
      line_list: format_line_list(line_list),
      total_count: total_count
    }
  end

  private
  def format_line_list(line_list)
    line_list.map do |line|
      {
        id: line.id,
        contractor: line.contractor && {
          id: line.contractor.id,
          tax_id: line.contractor.tax_id,
          th_company_name: line.contractor.th_company_name,
          en_company_name: line.contractor.en_company_name,
          contractor_user: {
            id: line.contractor_user_id,
            user_name: line.contractor_user&.user_name
          }
        },
        message_type:   line.message_type_label,
        message_body:   line.mask_message_body,
        send_status: line.send_status_label,
        updated_at:  line.updated_at
      }
    end
  end
end
