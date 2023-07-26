# frozen_string_literal: true

class Jv::LoginController < ApplicationController
  def login
    jv_user = JvUser.find_by(user_name: params[:user_name])

    # ログインエラー
    unless AuthJvUser.new(jv_user, params[:password]).call
      return render json: { success: false, errors: set_errors('error_message.login_error') }
    end

    # ログイン成功
    auth_token = jv_user.generate_auth_token
    jv_user.save_auth_token(auth_token)

    render json: { success: true, auth_token: auth_token }
  end
end
