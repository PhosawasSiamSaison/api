# frozen_string_literal: true

class Jv::UserUpdateController < ApplicationController
  before_action :auth_user

  def jv_user
    jv_user = JvUser.find(params[:jv_user_id])

    render json: { success: true, jv_user: format_jv_user(jv_user) }
  end

  def update_user
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    jv_user = JvUser.find(params[:jv_user][:id])

    jv_user.attributes = { update_user: login_user }

    if jv_user.update(jv_user_params)
      render json: { success: true }
    else
      render json: { success: false, errors: jv_user.error_messages }
    end
  end

  def delete_user
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    jv_user = JvUser.find(params[:jv_user_id])

    if login_user.id == jv_user.id
      return render json: { success: false, errors: set_errors('error_message.delete_own_account_error') }
    end

    jv_user.delete_with_auth_tokens

    render json: { success: true }
  end

  private

  def jv_user_params
    params.require(:jv_user).permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end

  def format_jv_user(jv_user)
    {
      user_name:     jv_user.user_name,
      full_name:     jv_user.full_name,
      email:         jv_user.email,
      user_type:     jv_user.user_type_label,
      updated_at:    jv_user.updated_at,
      update_user_name: jv_user.update_user&.full_name
    }
  end
end
