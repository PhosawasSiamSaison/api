# frozen_string_literal: true

class ProjectManager::LoginController < ApplicationController
  def login
    project_manager_user = ProjectManagerUser.find_by(user_name: params[:user_name])

    # ログインエラー
    unless AuthProjectManagerUser.new(project_manager_user, params[:password]).call
      return render json: { success: false, errors: set_errors('error_message.login_error') }
    end

    # ログイン成功
    auth_token = project_manager_user.generate_auth_token
    project_manager_user.save_auth_token(auth_token)

    render json: {
      success: true,
      auth_token: auth_token,
    }
  end
end
