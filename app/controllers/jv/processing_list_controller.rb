# frozen_string_literal: true

class Jv::ProcessingListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    contractors, total_count = Contractor.search_processing(params)

    render json: {
      success: true,
      contractors: format_contractors(contractors),
      total_count: total_count
    }
  end

  private
  def format_contractors(contractors)
    contractors.map do |contractor|
      {
        id: contractor.id,
        tax_id: contractor.tax_id,
        contractor_type: contractor.contractor_type_label[:label],
        en_company_name: contractor.en_company_name,
        th_company_name: contractor.th_company_name,
        approval_status: contractor.approval_status_label,
        application_number: contractor.application_number,
        created_at: contractor.created_at,
        is_applied_online: contractor.applied_online?,
        application_type_label: contractor.application_type_label,
      }
    end
  end
end
