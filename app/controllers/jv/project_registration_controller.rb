# frozen_string_literal: true

class Jv::ProjectRegistrationController < ApplicationController
  before_action :auth_user

  def create_project
    project = Project.new(project_params)
    project.attributes = {
      create_user: login_user,
      update_user: login_user
    }

    if project.save
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: project.error_messages
      }
    end
  end

  private

  def project_params
    params.require(:project).permit(:project_code, :project_type, :project_name, :project_manager_id,
      :project_limit, :project_value, :delay_penalty_rate, :project_owner, :start_ymd, :finish_ymd, :contract_registered_ymd, :address)
  end
end
