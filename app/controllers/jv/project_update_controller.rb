# frozen_string_literal: true

class Jv::ProjectUpdateController < ApplicationController
  before_action :auth_user

  def project
    project = Project.find(params[:project_id])

    render json: {
      success: true,
      project: {
        id: project.id,
        project_code: project.project_code,
        project_type: project.project_type_label,
        project_name: project.project_name,
        project_manager_id: project.project_manager.id,
        project_limit: project.project_limit.to_f,
        project_value: project.project_value.to_f,
        delay_penalty_rate: project.delay_penalty_rate,
        project_owner: project.project_owner,
        address: project.address,
        start_ymd: project.start_ymd,
        finish_ymd: project.finish_ymd,
        contract_registered_ymd: project.contract_registered_ymd,
        progress: project.progress,
        status: project.status_label
      }
    }
  end

  def update_project
    project = Project.find(params[:project_id])
    project.attributes = { update_user: login_user }

    if project.update(project_params)
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: project.error_messages
      }
    end
  end

  def delete_project
    project = Project.find(params[:project_id])

    # TODO: Projectは、Phaseがあれば削除不可
    project.update!(deleted: 1)

    render json: { success: true}
  end

  private

  def project_params
    params.require(:project).permit(:project_code, :project_type, :project_name, :project_manager_id,
      :project_limit, :delay_penalty_rate, :project_value, :project_owner, :start_ymd, :finish_ymd, :contract_registered_ymd, :status, :address, :progress)
  end
end
