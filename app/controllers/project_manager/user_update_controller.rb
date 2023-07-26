# frozen_string_literal: true

class ProjectManager::UserUpdateController < ApplicationController
  before_action :auth_user

  def project_manager_user
    project_manager_user =
      login_user.project_manager.project_manager_users.find(params[:project_manager_user_id])

    render json: { success: true,
      project_manager_user: {
        id: project_manager_user.id,
        user_name: project_manager_user.user_name,
        full_name: project_manager_user.full_name,
        mobile_number: project_manager_user.mobile_number,
        email: project_manager_user.email,
        user_type: project_manager_user.user_type_label,
        updated_at: project_manager_user.updated_at,
        update_user_name: project_manager_user.update_user&.full_name
      }
    }
  end

  def update_user
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    project_manager_user =
      login_user.project_manager.project_manager_users.find(params[:project_manager_user_id])

    project_manager_user.attributes = { update_user: login_user }

    if project_manager_user.update(project_manager_user_params)
      render json: { success: true }
    else
      render json: { success: false, errors: project_manager_user.error_messages }
    end
  end

  def delete_user
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    project_manager_user =
      login_user.project_manager.project_manager_users.find(params[:project_manager_user_id])

    if login_user.id == project_manager_user.id
      return render json: {
        success: false,
        errors: set_errors('error_message.delete_own_account_error')
      }
    end

    project_manager_user.delete_with_auth_tokens

    render json: { success: true }
  end

  private

  def project_manager_user_params
    params.require(:project_manager_user)
      .permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end
end
