# frozen_string_literal: true

class Jv::ContractorListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    contractors, total_count = Contractor.search_qualified(params)

    render json: {
      success:     true,
      contractors: format_contractors(contractors),
      total_count: total_count
    }
  end

  private

  def format_contractors(contractors)
    contractors.map do |contractor|
      {
        id:                    contractor.id,
        tax_id:                contractor.tax_id,
        contractor_type:       contractor.contractor_type_label[:label],
        use_only_credit_limit: contractor.use_only_credit_limit,
        en_company_name:       contractor.en_company_name,
        th_company_name:       contractor.th_company_name,
        registered_at:         contractor.registered_at,
        status:                contractor.status_label,
      }
    end
  end
end
