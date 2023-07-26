# frozen_string_literal: true

class Contractor::ChangeTempPasswordController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service

  def update_password
    if login_user.temp_password == params[:password]
      return render json: { success: false, errors: set_errors('error_message.duplicate_password_error') }
    end

    login_user.password = params[:password]

    if login_user.save(context: :password_update)
      # 更新が成功したらユーザデータを更新する
      login_user.update!(temp_password: nil)

      # メッセージ送信(RUDYログインの案内)
      SendMessage.login_to_rudy(login_user)

      render json: { success: true }
    else
      render json: { success: false, errors: login_user.error_messages }
    end
  end
end
