# frozen_string_literal: true

class Dealer::ContractorListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]
  def search
    contractors, total_count =
      login_user.dealer.contractors.search_qualified_for_dealer(params)

    render json: {
      success: true,
      contractors: format_contractors(contractors),
      total_count: total_count
    }
  end

  private
  def format_contractors(contractors)
    dealer = login_user.dealer

    contractors.map do |contractor|
      {
        id: contractor.id,
        tax_id: contractor.tax_id,
        contractor_type: contractor.contractor_type_label[:label],
        en_company_name: contractor.en_company_name,
        th_company_name: contractor.th_company_name,
        credit_limit:    contractor.dealer_limit_amount(dealer),
        used_amount:     contractor.dealer_remaining_principal(dealer),
        available_balance: contractor.dealer_available_balance(dealer),
        registered_at: contractor.registered_at,
        updated_at: contractor.updated_at,
        status: contractor.status_label
      }
    end
  end
end
