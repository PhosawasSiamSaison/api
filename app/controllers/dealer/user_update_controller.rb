# frozen_string_literal: true

class Dealer::UserUpdateController < ApplicationController
  before_action :auth_user

  def dealer_user
    dealer_user = login_user.dealer.dealer_users.find(params[:dealer_user_id])

    render json: { success: true, dealer_user: format_dealer_user(dealer_user) }
  end

  def update_user
    # 権限チェック
    errors = check_permission_errors(login_user.owner?)
    return render json: { success: false, errors:  errors } if errors.present?

    dealer_user = login_user.dealer.dealer_users.find(params[:dealer_user][:id])

    dealer_user.attributes = { update_user: login_user }

    if dealer_user.update(dealer_user_params)
      render json: { success: true }
    else
      render json: { success: false, errors: dealer_user.error_messages }
    end
  end

  def delete_user
    # 権限チェック
    errors = check_permission_errors(login_user.owner?)
    return render json: { success: false, errors:  errors } if errors.present?

    dealer_user = login_user.dealer.dealer_users.find(params[:dealer_user_id])

    if login_user.id == dealer_user.id
      return render json: { success: false, errors: set_errors('error_message.delete_own_account_error') }
    end

    dealer_user.delete_with_auth_tokens

    render json: { success: true }
  end

  private

  def dealer_user_params
    params.require(:dealer_user).permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end

  def format_dealer_user(dealer_user)
    {
      user_name:     dealer_user.user_name,
      full_name:     dealer_user.full_name,
      mobile_number: dealer_user.mobile_number,
      email:         dealer_user.email,
      user_type:     dealer_user.user_type_label,
      updated_at:    dealer_user.updated_at,
      update_user_name: dealer_user.update_user&.full_name
    }
  end
end
