# frozen_string_literal: true

class Dealer::UserRegistrationController < ApplicationController
  before_action :auth_user

  def create_user
    # 権限チェック
    errors = check_permission_errors(login_user.owner?)
    return render json: { success: false, errors:  errors } if errors.present?

    dealer_user = login_user.dealer.dealer_users.new(dealer_user_params)

    dealer_user.attributes = { create_user: login_user, update_user: login_user }

    if dealer_user.save
      render json: { success: true }
    else
      render json: { success: false, errors: dealer_user.error_messages }
    end
  end

  private

  def dealer_user_params
    params.require(:dealer_user).permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end
end
