# frozen_string_literal: true

class Contractor::ProjectListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  # 検索条件あり
  def search
    projects = Project.search_for_contractor(params, login_user)

    render json: {
      success: true,
      projects: projects.map do |project|
        {
          id: project.id,
          project_code: project.project_code,
          project_name: project.project_name,
          project_manager: {
            id: project.project_manager.id,
            project_manager_name: project.project_manager.project_manager_name,
          },
          start_ymd: project.start_ymd,
          finish_ymd: project.finish_ymd,
          status: project.status_label,
        }
      end
    }
  end
end
