# frozen_string_literal: true

class ProjectManager::UserRegistrationController < ApplicationController
  before_action :auth_user

  def create_user
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    project_manager_user = ProjectManagerUser.new(project_manager_user_params)
    project_manager_user.project_manager = login_user.project_manager

    project_manager_user.attributes = { 
      create_user: login_user,
      update_user: login_user 
    }

    if project_manager_user.save
      render json: { success: true }
    else
      render json: { success: false, errors: project_manager_user.error_messages }
    end
  end

  private

  def project_manager_user_params
    params.require(:project_manager_user).permit(:user_name, :full_name, :mobile_number, :email, :user_type, :password)
  end
end
