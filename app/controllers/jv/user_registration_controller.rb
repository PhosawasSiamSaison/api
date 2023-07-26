# frozen_string_literal: true

class Jv::UserRegistrationController < ApplicationController
  before_action :auth_user

  def create_user
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    jv_user = JvUser.new(jv_user_params)

    jv_user.attributes = { create_user: login_user, update_user: login_user }

    if jv_user.save
      render json: { success: true }
    else
      render json: { success: false, errors: jv_user.error_messages }
    end
  end

  private

  def jv_user_params
    params.require(:jv_user).permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end
end
