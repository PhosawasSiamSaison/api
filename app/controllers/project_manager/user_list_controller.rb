# frozen_string_literal: true

class ProjectManager::UserListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    project_manager_users = login_user.project_manager.project_manager_users

    paginated_project_manager_users, total_count = [
      project_manager_users.paginate(params[:page], project_manager_users, params[:per_page]), project_manager_users.count
    ]

    render json: {
      success:     true,
      project_manager_users: project_manager_users.map do |project_manager_user|
        {
          id:             project_manager_user.id,
          user_type:      project_manager_user.user_type_label,
          user_name:      project_manager_user.user_name,
          full_name:      project_manager_user.full_name,
          mobile_number:  project_manager_user.mobile_number,
          email:          project_manager_user.email,
          create_user_id: project_manager_user.create_user_id,
          update_user_id: project_manager_user.update_user_id,
          created_at:     project_manager_user.created_at,
          updated_at:     project_manager_user.updated_at
        }
      end,
      total_count: total_count
    }
  end
end
