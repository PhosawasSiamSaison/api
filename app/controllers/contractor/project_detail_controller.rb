# frozen_string_literal: true

class Contractor::ProjectDetailController < ApplicationController
  before_action :auth_user

  def project
    project = login_user.contractor.projects.find(params[:project_id])

    render json: {
      success: true,
      project: {
        id: project.id,
        project_code: project.project_code,
        project_type: project.project_type_label,
        project_name: project.project_name,
        project_manager: {
            id: project.project_manager.id,
            project_manager_name: project.project_manager.project_manager_name,
        },
        start_ymd: project.start_ymd,
        finish_ymd: project.finish_ymd,
        status: project.status_label
      }
    }
  end

  def project_phase_list
    contractor = login_user.contractor

    project_phases = Project.find(params[:project_id]).project_phases

    target_project_phases = project_phases.includes(:project_phase_sites, :contractors)
      .where(project_phase_sites: { contractor: contractor })

    render json: {
      success: true,
      phases: target_project_phases.map {|phase|
        site = phase.project_phase_sites.find_by(contractor: contractor)
        target_orders = site.payment_list_orders_only_input_ymd

        # オーダーなしは除外する
        next if target_orders.blank?

        {
          id: phase.id,
          phase_number: phase.phase_number,
          phase_name: phase.phase_name,
          status: phase.status_label,
          site_limit: site.site_limit,
          used_amount: site.used_amount,
          refund: site.refund_amount.to_f,
          site_code: site.site_code,
          site_name: site.site_name,
          orders: target_orders.map {|order|
            installment = order.installments.first

            {
              id: order.id,
              order_number: order.order_number,
              status: format_status(installment),
              purchase_ymd: order.purchase_ymd,
              due_ymd: installment.due_ymd,
              paid_up_ymd: order.paid_up_ymd,
              total_amount: installment.calc_total_amount,
              payment_amount: installment.paid_total_amount,
              dealer: {
                id: order.dealer.dealer_name,
                dealer_name: order.dealer.dealer_name,
                dealer_type: order.dealer.dealer_type_label,
              }
            }
          }
        }
      }.compact
    }
  end

  private
    # アイコン表示用のステータス
    def format_status(installment)
      if installment.paid?
        'paid'
      elsif installment.over_due?
        'over_due'
      else
        nil
      end
    end
end
