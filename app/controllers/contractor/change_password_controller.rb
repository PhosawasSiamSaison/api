# frozen_string_literal: true

class Contractor::ChangePasswordController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def update_password
    if login_user.authenticate(params[:current_password]).present?
      # 現在、使用中のパスワードの認証が成功した場合に実行される
      login_user.password = params[:new_password]
    else
      return render json: { success: false, errors: set_errors('error_message.current_password_error') }
    end

    if login_user.save(context: :password_update)
      render json: { success: true }
    else
      render json: { success: false, errors: login_user.error_messages }
    end
  end
end
