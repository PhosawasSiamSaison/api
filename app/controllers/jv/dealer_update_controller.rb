# frozen_string_literal: true

class Jv::DealerUpdateController < ApplicationController
  before_action :auth_user

  def update_dealer
    dealer = Dealer.find(params[:dealer][:id])

    dealer.attributes = { update_user_id: login_user.id }

    if dealer.update(dealer_params)
      render json: { success: true }
    else
      render json: { success: false, errors: dealer.error_messages }
    end
  end

  private

  def dealer_params
    params.require(:dealer).permit(:tax_id, :area_id,  :dealer_type, :dealer_code, :dealer_name,
      :en_dealer_name, :bank_account, :address, :status,
      :for_normal_rate, :for_government_rate, :for_sub_dealer_rate, :for_individual_rate)
  end
end
