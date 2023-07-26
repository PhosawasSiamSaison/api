# frozen_string_literal: true

class Jv::DealerDetailController < ApplicationController
  before_action :auth_user

  def dealer
    dealer = Dealer.find(params[:dealer_id])

    render json: { success: true, dealer: format_dealer(dealer) }
  end

  def dealer_users
    dealer_users = DealerUser.where(dealer_id: params[:dealer_id])

    render json: { success: true, dealer_users: format_dealer_users(dealer_users) }
  end

  def create_dealer_user
    dealer_user = DealerUser.new(dealer_user_create_params)

    dealer_user.attributes = { create_user: login_user, update_user: login_user }

    if dealer_user.save
      render json: { success: true }
    else
      render json: { success: false, errors: dealer_user.error_messages }
    end
  end

  def dealer_user
    dealer_user = DealerUser.find(params[:dealer_user_id])

    render json: { success: true, dealer_user: format_dealer_user(dealer_user) }
  end

  def update_dealer_user
    dealer_user = DealerUser.find(params[:dealer_user][:id])

    dealer_user.attributes = { update_user: login_user }

    if dealer_user.update(dealer_user_update_params)
      render json: { success: true }
    else
      render json: { success: false, errors: dealer_user.error_messages }
    end
  end

  def delete_dealer_user
    dealer_user = DealerUser.find(params[:dealer_user_id])

    dealer_user.delete_with_auth_tokens

    render json: { success: true }
  end

  private

  def dealer_user_create_params
    params.require(:dealer_user)
      .permit(:dealer_id, :user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end

  def dealer_user_update_params
    params.require(:dealer_user)
      .permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end

  def format_dealer(dealer)
    {
      id:           dealer.id,
      tax_id:       dealer.tax_id,
      dealer_type:  dealer.dealer_type_label,
      dealer_code:  dealer.dealer_code,
      dealer_name:  dealer.dealer_name,
      en_dealer_name: dealer.en_dealer_name,
      bank_account: dealer.bank_account,
      address:      dealer.address,
      status:       dealer.status_label,
      created_at:   dealer.created_at,
      updated_at:   dealer.updated_at,
      area: {
        id:        dealer.area_id,
        area_name: dealer.area.area_name
      },
      transaction_fee: {
        for_normal_rate:     dealer.for_normal_rate.to_f,
        for_sub_dealer_rate: dealer.for_sub_dealer_rate.to_f,
        for_government_rate: dealer.for_government_rate.to_f,
        for_individual_rate: dealer.for_individual_rate.to_f,
      },
      update_user_name: dealer.update_user&.full_name
    }
  end

  def format_dealer_users(dealer_users)
    dealer_users.map do |dealer_user|
      {
        id:             dealer_user.id,
        user_type:      dealer_user.user_type_label,
        user_name:      dealer_user.user_name,
        full_name:      dealer_user.full_name,
        mobile_number:  dealer_user.mobile_number,
        email:          dealer_user.email,
        agreed_at:      dealer_user.agreed_at,
        create_user_id: dealer_user.create_user_id,
        update_user_id: dealer_user.update_user_id,
        created_at:     dealer_user.created_at,
        updated_at:     dealer_user.updated_at,
        update_user_name: dealer_user.update_user&.full_name
      }
    end
  end

  def format_dealer_user(dealer_user)
    {
      user_name:     dealer_user.user_name,
      full_name:     dealer_user.full_name,
      mobile_number: dealer_user.mobile_number,
      email:         dealer_user.email,
      user_type:     dealer_user.user_type_label
    }
  end
end
