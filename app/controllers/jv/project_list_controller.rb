# frozen_string_literal: true

class Jv::ProjectListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  # 検索条件あり
  def search
    projects, total_count = Project.search(params)

    render json: {
      success: true,
      projects: projects.map do |project|
        {
          id: project.id,
          project_code: project.project_code,
          project_type: project.project_type_label,
          project_name: project.project_name,
          project_manager: {
            id: project.project_manager.id,
            project_manager_name: project.project_manager.project_manager_name
          },
          project_value: project.project_value.to_f,
          start_date: project.start_ymd,
          progress: project.progress,
          status: project.status_label,
          contractors: project.contractors.distinct.map do |contractor|
            {
              id: contractor.id,
              th_company_name: contractor.th_company_name,
              en_company_name: contractor.en_company_name
            }
          end
        }
      end,
      total_count: total_count
    }
  end

  def project_managers
    managers = ProjectManager.all

    render json: {
      success: true,
      project_managers: managers.map do |manager|
        {
          id: manager.id,
          project_manager_name: manager.project_manager_name
        }
      end
    }
  end
end
