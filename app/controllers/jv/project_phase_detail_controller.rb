# frozen_string_literal: true

class Jv::ProjectPhaseDetailController < ApplicationController
  before_action :auth_user

  def project_phase
    phase = ProjectPhase.find(params[:project_phase_id])

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
        progress: phase.average_progress,
      }
    }
  end

  def project_basic_information
    project = ProjectPhase.find(params[:project_phase_id]).project

    render json: {
      success: true,
      project: {
        project_code: project.project_code,
        project_name: project.project_name
      }
    }
  end

  def update_project_phase
    phase = ProjectPhase.find(params[:project_phase_id])

    if phase.update(project_phase_params)
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: phase.error_messages
      }
    end
  end

  def delete_project_phase
    phase = ProjectPhase.find(params[:project_phase_id])

    # Phaseは、Siteがあれば削除不可
    if phase.project_phase_sites.blank?
      phase.update!(deleted: true)
    else
      return render json: { success: false, errors: ['Phase has sites.'] }
    end

    render json: { success: true }
  end


  # Payment from Project Owner/Manager
  def payment_detail
    phase = ProjectPhase.find(params[:project_phase_id])

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


  # Evidence

  def evidence_list
    phase = ProjectPhase.find(params[:project_phase_id])
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

  def evidence
    evidence = ProjectPhaseEvidence.find(params[:project_phase_evidence_id])
    evidences = evidence.project_phase.project_phase_evidences.order(created_at: :desc, id: :desc)
    prev_evidence_id = evidences.get_prev_id(evidence)
    next_evidence_id = evidences.get_next_id(evidence)

    render json: {
      success: true,
      prev_evidence_id: prev_evidence_id,
      next_evidence_id: next_evidence_id,
      evidence: {
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
    }
  end

  def update_evidence_check
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors: errors } if errors.present?

    evidence = ProjectPhaseEvidence.find(params[:project_phase_evidence_id])

    if params[:update_evidence_check_to] == true && evidence.checked_at.blank?
      # evidenceのチェックがされてないときにチェックをクリックすると実行される
      evidence.update!(
        checked_at: Time.zone.now,
        checked_user_id: login_user.id
      )
    elsif params[:update_evidence_check_to] == false && evidence.checked_at.present?
      evidence.update!(
        checked_at: nil,
        checked_user_id: nil
      )
    else
      #TODO: 業務エラーを設計した際に修正する
      return render json: { success: false, errors: ['invalid_value_of_update_evidence_check_to'] }
    end

    render json: { success: true }
  end


  # Site

  def create_project_phase_site
    phase = ProjectPhase.find(params[:project_phase_id])
    contractor = Contractor.find(params[:contractor_id])
    site = phase.project_phase_sites.new(project_phase_site_params)

    site.contractor = contractor
    site.create_user = login_user
    site.update_user = login_user

    if site.save(context: :update_site_limit)
      # RUDYのAPIを呼ぶ
      RudyCreateSite.new(site).exec

      render json: { success: true }
    else
      render json: {
        success: false,
        errors: site.error_messages
      }
    end
  end

  def update_project_phase_site
    site = ProjectPhaseSite.find(params[:project_phase_site_id])
    contractor = Contractor.find(params[:contractor_id])

    site.contractor = contractor
    site.update_user = login_user

    if site.valid?(:update_site_limit) && site.update(project_phase_site_update_params)
      render json: { success: true }
    else
      render json: {
        success: false,
        errors: site.error_messages
      }
    end
  end

  def delete_project_phase_site
    site = ProjectPhaseSite.find(params[:project_phase_site_id])

    # TODO: Siteは、Orderがあれば削除不可
    site.update!(deleted: 1)

    render json: { success: true }
  end

  def project_phase_site_list
    project_phase_sites = ProjectPhase.find(params[:project_phase_id]).project_phase_sites
    target_ymds = JSON.parse(params[:target_ymds])

    progress_data = project_phase_sites.progress_data

    render json: {
      success: true,
      sites: project_phase_sites.map do |project_phase_site|
        target_ymd = target_ymds[project_phase_site.id.to_s] || BusinessDay.today_ymd

        {
          id: project_phase_site.id,
          site_code:   project_phase_site.site_code,
          site_name:   project_phase_site.site_name,
          phase_limit: project_phase_site.phase_limit.to_f,
          site_limit:  project_phase_site.site_limit.to_f,
          progress:    progress_data[project_phase_site.site_code],
          status:      project_phase_site.status_label,
          contractor: {
            id:              project_phase_site.contractor.id,
            tax_id:          project_phase_site.contractor.tax_id,
            th_company_name: project_phase_site.contractor.th_company_name,
            en_company_name: project_phase_site.contractor.en_company_name,
          },
          paid_up_ymd: project_phase_site.paid_up_ymd,
          used_amount:       project_phase_site.used_amount,
          available_balance: project_phase_site.available_balance,
          refund_amount:     project_phase_site.refund_amount.to_f,
          order_total_amount: {
            principal:        project_phase_site.total_principal,
            interest:         project_phase_site.total_interest,
            late_charge:      project_phase_site.calc_total_late_charge(target_ymd),
            paid_principal:   project_phase_site.total_paid_principal,
            paid_interest:    project_phase_site.total_paid_interest,
            paid_late_charge: project_phase_site.total_paid_late_charge,
          },
          orders: project_phase_site.payment_list_orders.map { |order|
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
    site = ProjectPhaseSite.find(params[:project_phase_site_id])

    render json: {
      success: true,
      site: {
        id: site.id,
        site_code: site.site_code,
        site_name: site.site_name,
        phase_limit: site.phase_limit.to_f,
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


  # Receive History

  def receive_amount_history
    project_phase = ProjectPhase.find(params[:project_phase_id])
    project_receive_amount_histories = project_phase.project_receive_amount_histories.order(:created_at)

    # ページングして取得
    total_count = project_receive_amount_histories.count
    receive_amount_histories =
      ApplicationRecord.paginate(params[:page], project_receive_amount_histories, params[:per_page])

    render json: {
      success: true,
      receive_amount_histories: receive_amount_histories.map {|row|
        {
          id: row.id,
          receive_ymd: row.receive_ymd,
          receive_amount: row.receive_amount.to_f,
          comment: row.comment,
          no_delay_penalty_amount: row.exemption_late_charge.to_f,
          site: {
            site_name: row.project_phase_site.site_name,
            site_code: row.project_phase_site.site_code,
            contractor: {
              tax_id: row.contractor.tax_id,
              en_company_name: row.contractor.en_company_name,
              th_company_name: row.contractor.th_company_name,
            }
          },
          create_user: {
            id: row.create_user.id,
            full_name: row.create_user.full_name,
          },
          created_at: row.created_at,
          lock_version: row.lock_version,
        }
      },
      total_count: total_count,
      can_edit_comment: login_user.system_admin || login_user.md?
    }
  end

  def update_history_comment
    project_receive_amount_history =
      ProjectReceiveAmountHistory.find(params[:receive_amount_history][:id])

    if project_receive_amount_history.update(comment: params[:receive_amount_history][:comment])
      render json: { success: true }
    else
      render json: { success: false, errors: project_receive_amount_history.error_messages }
    end
  end

  # 入金(消し込み)処理
  def receive_payment
    project_phase_site_id = params[:project_phase_site_id]
    payment_ymd    = params[:payment_ymd]
    payment_amount = params[:payment_amount]
    comment        = params[:comment]
    is_exemption_late_charge = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除

    project_phase_site = ProjectPhaseSite.find(project_phase_site_id)

    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors: errors } if errors.present?

    # 日付の未来日チェック
    if BusinessDay.today_ymd < payment_ymd
      return render json: { success: false, errors: [I18n.t('error_message.invalid_future_date')] }
    end

    # TODO Switchを対応する際に有効にする
    # 消し込み可能かつ商品変更の申請をされているオーダーがある場合はエラー
    # if contractor.has_can_repayment_and_applying_change_product_orders?
    #   return render json: {
    #     success: false,
    #     errors: [I18n.t('error_message.has_can_repayment_and_applying_change_product_orders')]
    #   }
    # end

    ActiveRecord::Base.transaction do
      AppropriateProjectOrders.new.call(project_phase_site, payment_ymd, payment_amount, login_user,
        comment, is_exemption_late_charge
      )

      project_phase = project_phase_site.project_phase
      params_history_count = params.fetch(:receive_amount_history_count).to_i

      # 排他チェック
      # ラグを減らすために消し込み後に実行
      # 消し込みでreceive_amount_historiesが作成されるので引数に1をプラスして比較する
      if project_phase.project_receive_amount_histories.count != params_history_count + 1
        raise ActiveRecord::StaleObjectError
      end
    end

    render json: {
      success: true
    }
  end

  private

  def project_phase_site_params
    params.require(:project_phase_site).permit(:site_code, :site_name, :phase_limit)
  end

  def project_phase_site_update_params
    params.require(:project_phase_site).permit(:site_name, :phase_limit, :status)
  end

  def project_phase_params
    params.require(:phase)
      .permit(:phase_name, :phase_value, :phase_limit, :start_ymd, :finish_ymd, :due_ymd, :status)
  end
end
