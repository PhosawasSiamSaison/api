# frozen_string_literal: true

class Dealer::LoginController < ApplicationController
  def login
    dealer_user = DealerUser.find_by(user_name: params[:user_name])

    # ログインエラー
    unless AuthDealerUser.new(dealer_user, params[:password]).call
      return render json: { success: false, errors: set_errors('error_message.login_error') }
    end

    # ログイン成功
    auth_token = dealer_user.generate_auth_token
    dealer_user.save_auth_token(auth_token)

    render json: {
      success:           true,
      auth_token:        auth_token,
      require_agreement: dealer_user.agreed_at.blank?
    }
  end
end
