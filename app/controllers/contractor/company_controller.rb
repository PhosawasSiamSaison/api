# frozen_string_literal: true

class Contractor::CompanyController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def company_info
    contractor = login_user.contractor

    render json: { success: true, contractor: format_contractor(contractor) }
  end

  private

  def format_contractor(contractor)
    {
      tax_id:              contractor.tax_id,
      th_company_name:     contractor.th_company_name,
      en_company_name:     contractor.en_company_name,
      address:             contractor.address,
      phone_number:        contractor.phone_number,
      registration_no:     contractor.registration_no,
      establish_year:      contractor.establish_year,
      establish_month:     contractor.establish_month,
      employee_count:      contractor.employee_count,
      capital_fund_mil:    contractor.capital_fund_mil,
      shareholders_equity: contractor.shareholders_equity,
      recent_revenue:      contractor.recent_revenue,
      short_term_loan:     contractor.short_term_loan,
      long_term_loan:      contractor.long_term_loan,
      recent_profit:       contractor.recent_profit,
    }
  end
end
