# frozen_string_literal: true

class ProjectManager::ProjectPhaseDetailController < ApplicationController
  before_action :auth_user

  def project_phase
    phase = login_user.project_manager.project_phases.find(params[:project_phase_id])

    render json: {
      success: true,
      phase: {
        id: phase.id,
        phase_number: phase.phase_number,
        phase_name: phase.phase_name,
        phase_value: phase.phase_value.to_f,
        phase_limit: phase.phase_limit.to_f,
        start_ymd: phase.start_ymd,
        finish_ymd: phase.finish_ymd,
        due_ymd: phase.due_ymd,
        status: phase.status_label,
        lock_version: phase.lock_version,
        is_closed: phase.closed?,
        progress: phase.average_progress,
      }
    }
  end

  def project_basic_information
    project = login_user.project_manager.project_phases.find(params[:project_phase_id]).project

    render json: {
      success: true,
      project: {
        project_code: project.project_code,
        project_name: project.project_name
      }
    }
  end

  def payment_detail
    phase = login_user.project_manager.project_phases.find(params[:project_phase_id])

    render json: {
      success: true,
      due_ymd: phase.due_ymd,
      phase_value: phase.phase_value.to_f,
      phase_limit: phase.phase_limit.to_f,
      paid_up_ymd: phase.paid_up_ymd,
      surcharge: phase.surcharge_amount,
      # フロントでテーブル要素を使用しているので配列形式で渡す
      repayment_amount_data: [
        paid_amount: phase.paid_repayment_amount,
        amount: phase.repayment_amount,
      ]
    }
  end

  def upload_evidence
    phase = login_user.project_manager.project_phases.find(params[:project_phase_id])
    evidence = phase.project_phase_evidences.new(upload_evidence_params)

    max_evidence_number = ProjectPhaseEvidence.unscope(where: :deleted).maximum(:evidence_number)
    evidence.evidence_number = (max_evidence_number.to_i + 1).to_s.rjust(10, '0')

    if evidence.save
      file = parse_base64(params[:evidence][:file_data])
      evidence.file.attach(io: file, filename: params[:evidence][:file_name])

      render json: { success: true }
    else
      render json: {
        success: false,
        errors: evidence.error_messages
      }
    end
  end

  def evidence_list
    phase = login_user.project_manager.project_phases.find(params[:project_phase_id])
    evidences = phase.project_phase_evidences.sort_list

    paginated_evidences, total_count = [
      evidences.paginate(params[:page], evidences, params[:per_page]), evidences.count
    ]

    render json: {
      success: true,
      evidences: paginated_evidences.map do |evidence|
        {
          id: evidence.id,
          evidence_number: evidence.evidence_number,
          comment: evidence.comment,
          checked_at: evidence.checked_at,
          checked_user: {
            id: evidence.checked_user_id,
            user_name: evidence.checked_user&.user_name
          },
          created_at: evidence.created_at,
          payment_image_url: url_for(evidence.file)
        }
      end,
      total_count: total_count
    }
  end

  def project_phase_site_list
    sites =
      login_user.project_manager.project_phases.find(params[:project_phase_id]).project_phase_sites

    target_ymd = BusinessDay.today_ymd

    progress_data = sites.progress_data

    render json: {
      success: true,
      sites: sites.map do |site|
        {
          id: site.id,
          site_code: site.site_code,
          site_name: site.site_name,
          phase_limit: site.phase_limit.to_f,
          site_limit: site.site_limit.to_f,
          progress: progress_data[site.site_code],
          status: site.status_label,
          contractor: {
            id: site.contractor.id,
            tax_id: site.contractor.tax_id,
            th_company_name: site.contractor.th_company_name,
            en_company_name: site.contractor.en_company_name,
          },
          paid_up_ymd: site.paid_up_ymd,
          used_amount:       site.used_amount,
          available_balance: site.available_balance,
          refund_amount:     site.refund_amount.to_f,
          order_total_amount: {
            principal:        site.total_principal,
            interest:         site.total_interest,
            late_charge:      site.calc_total_late_charge(target_ymd),
            paid_principal:   site.total_paid_principal,
            paid_interest:    site.total_paid_interest,
            paid_late_charge: site.total_paid_late_charge,
          },
          orders: site.payment_list_orders.map { |order|
            dealer = order.dealer
            installment = order.installments.first

            {
              id: order.id,
              order_number: order.order_number,
              paid_up_ymd: installment.paid_up_ymd,
              dealer: {
                id: dealer.id,
                dealer_type: dealer.dealer_type_label,
                dealer_name: dealer.dealer_name,
              },
              input_ymd:        order.input_ymd,
              due_ymd:          installment.due_ymd,
              paid_principal:   installment.paid_principal.to_f,
              principal:        installment.principal.to_f,
              paid_interest:    installment.paid_interest.to_f,
              interest:         installment.interest.to_f,
              paid_late_charge: installment.paid_late_charge.to_f,
              late_charge:      installment.calc_late_charge(target_ymd),
            }
          }
        }
      end
    }
  end

  def project_phase_site
    site = login_user.project_manager.project_phase_sites.find(params[:project_phase_site_id])

    render json: {
      success: true,
      site: {
        id: site.id,
        site_code: site.site_code,
        site_name: site.site_name,
        phase_limit: site.phase_limit.to_f,
        site_limit: site.site_limit.to_f,
        status: site.status_label,
        contractor: {
          id: site.contractor.id,
          tax_id: site.contractor.tax_id,
          th_company_name: site.contractor.th_company_name,
          en_company_name: site.contractor.en_company_name,
        }
      }
    }
  end

  def update_site_limit
    site = login_user.project_manager.project_phase_sites.find(params[:project_phase_site_id])

    if site.update(site_limit: params[:site_limit])
      render json: { success: true }
    else
      render json: {
          success: false,
          errors: site.error_messages
      }
    end
  end

  private

  def upload_evidence_params
    params.require(:evidence).permit(:comment)
  end
end
