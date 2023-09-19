# frozen_string_literal: true

class Jv::DealerRegistrationController < ApplicationController
  before_action :auth_user

  def new_dealer
    dealer = Dealer.new

    render json: {
      success: true,
      default_values: {
        for_normal_rate: dealer.for_normal_rate.to_f,
        for_government_rate: dealer.for_government_rate.to_f,
        for_sub_dealer_rate: dealer.for_sub_dealer_rate.to_f,
        for_individual_rate: dealer.for_individual_rate.to_f,
      }
    }
  end

  def create_dealer
    dealer = Dealer.new(dealer_params)

    dealer.attributes = { create_user_id: login_user.id, update_user_id: login_user.id }

    if dealer.save
      dealer.create_transaction_fee_history
      render json: { success: true }
    else
      render json: { success: false, errors: dealer.error_messages }
    end
  end

  private

  def dealer_params
    params.require(:dealer).permit(:tax_id, :area_id, :dealer_type, :dealer_code, :dealer_name,
      :en_dealer_name, :bank_account, :address, :status,
      :for_normal_rate, :for_government_rate, :for_sub_dealer_rate, :for_individual_rate)
  end
end
