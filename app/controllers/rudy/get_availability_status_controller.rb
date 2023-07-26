# frozen_string_literal: true

class Rudy::GetAvailabilityStatusController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    tax_id = params[:tax_id]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    return render json: {
      result: "OK",
      credit_limit: contractor.credit_limit_amount,
      used_amount: contractor.remaining_principal,
      available_balance: contractor.available_balance,
      cashback_amount: contractor.cashback_amount,
      availability_status: contractor.active? ? "available" : "unavailable",
      available_dealer_codes: contractor.available_dealer_codes,
    }
  end

  private
  def render_demo_response
    tax_id = params[:tax_id]

    # Success
    if tax_id == '1234567890111'
      return render json: {
        result: "OK",
        credit_limit: 15000.0,
        used_amount: 13000.0,
        available_balance: 2000.0,
        cashback_amount: 600.0,
        availability_status: "available",
        available_dealer_codes: [],
      }
    end

    # Error : contractor_not_found
    raise(ValidationError, 'contractor_not_found') if tax_id == '1234567890000'

    # 一致しない
    raise NoCaseDemo
  end
end
