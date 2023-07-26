# frozen_string_literal: true

class Rudy::GetDealerCreditStatusController < Rudy::ApplicationController
  def call
    tax_id = params[:tax_id]
    dealer_code = params[:dealer_code]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    dealer = Dealer.find_by(dealer_code: dealer_code)
    raise(ValidationError, 'dealer_not_found') if dealer.blank?

    if !contractor.dealer_without_limit_setting?(dealer)
      raise(ValidationError, 'dealer_without_limit_setting')
    end

    if !contractor.available_any_purchase?(dealer.dealer_type)
      raise(ValidationError, 'unavailable_purchase_setting')
    end

    dealer_type = dealer.dealer_type

    return render json: {
      result: "OK",
      dealer_type: dealer.dealer_type_before_type_cast, # 整数値を返す
      dealer_type_credit_limit:      contractor.dealer_type_limit_amount(dealer_type),
      dealer_type_used_amount:       contractor.dealer_type_remaining_principal(dealer_type),
      dealer_type_available_balance: contractor.dealer_type_available_balance(dealer_type),
      dealer_credit_limit:           contractor.dealer_limit_amount(dealer),
      dealer_used_amount:            contractor.dealer_remaining_principal(dealer),
      dealer_available_balance:      contractor.dealer_available_balance(dealer),
    }
  end
end
