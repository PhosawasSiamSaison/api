# frozen_string_literal: true

class ProjectManager::ProjectListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  # 検索条件あり
  def search
    projects, total_count = Project.search_for_project_manager(params, login_user)

    render json: {
      success: true,
      projects: projects.map {|project|
        {
          id: project.id,
          project_code: project.project_code,
          project_type: project.project_type_label,
          project_name: project.project_name,
          project_value: project.project_value.to_f,
          project_limit: project.project_limit.to_f,
          delay_penalty_rate: project.delay_penalty_rate.to_f,
          project_owner: project.project_owner,
          contractors: project.contractors.distinct.map do |contractor|
            {
              id: contractor.id,
              th_company_name: contractor.th_company_name,
              en_company_name: contractor.en_company_name
            }
          end,
          start_ymd: project.start_ymd,
          finish_ymd: project.finish_ymd,
          contract_registered_ymd: project.contract_registered_ymd,
          progress: project.progress,
          status: project.status_label,
          purchase_amount: project.total_purchase_amount,
          paid_repayment_amount: project.paid_total_amount_with_refund,
          repayment_amount: project.project_value.to_f,
        }
      },
      total_count: total_count
    }
  end
end
