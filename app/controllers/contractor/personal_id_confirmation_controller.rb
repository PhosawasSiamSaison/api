# frozen_string_literal: true

class Contractor::PersonalIdConfirmationController < ApplicationController
  def auth_personal_id
    user_name = params[:user_name]
    initialize_token = params[:access_key]

    contractor_user = ContractorUser.find_by(user_name: user_name, initialize_token: initialize_token)

    # 不正なURLトークン
    if contractor_user.blank?
      return render json: { success: false, errors: set_errors('error_message.auth_error') }
    end

    # 初期パスワード設定＆規約同意済み
    if contractor_user.temp_password.blank?
      return render json: { success: false, errors: set_errors('error_message.account_has_already_activated') }
    end

    # 認証成功
    SendMessage.send_personal_id_confirmed(contractor_user)

    render json: { success: true }
  end
end