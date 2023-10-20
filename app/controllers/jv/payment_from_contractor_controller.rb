# frozen_string_literal: true

class Jv::PaymentFromContractorController < ApplicationController
  before_action :auth_user

  def payment_list
    target_ymd = params[:target_ymd]
    contractor = Contractor.find(params[:contractor_id])
    payments   = contractor.payments.payment_from_contractor_payments
    is_exemption_late_charge = params[:no_delay_penalty].to_s == "true"

    render json: {
      success: true,
      payments: format_payments(contractor, payments, target_ymd, is_exemption_late_charge)
    }
  end

  def evidence_list
    contractor = Contractor.find(params[:contractor_id])
    evidences  = contractor.evidences.sort_list

    paginated_evidences, total_count = [
      evidences.paginate(params[:page], evidences, params[:per_page]), evidences.count
    ]

    render json: {
      success:     true,
      evidences:   format_evidence_list(paginated_evidences),
      total_count: total_count
    }
  end

  def get_evidence
    evidence         = Evidence.find(params[:evidence_id])
    evidences        = evidence.contractor.evidences.order(created_at: :desc, id: :desc)
    prev_evidence_id = evidences.get_prev_id(evidence)
    next_evidence_id = evidences.get_next_id(evidence)

    render json: {
      success:          true,
      prev_evidence_id: prev_evidence_id,
      next_evidence_id: next_evidence_id,
      evidence:         format_evidence(evidence)
    }
  end

  def update_evidence_check
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    evidence = Evidence.find(params[:evidence_id])

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

  def contractor_status
    contractor    = Contractor.find(params[:contractor_id])

    contractor_status = {
      tax_id:                     contractor.tax_id,
      th_company_name:            contractor.th_company_name,
      en_company_name:            contractor.en_company_name,
      contractor_type:            contractor.contractor_type_label[:label],
      cashback_amount:            contractor.cashback_amount,
      over_payment_amount:        contractor.exceeded_amount,
      business_ymd:               BusinessDay.today_ymd,
      exempt_delay_penalty_count: contractor.exemption_late_charge_count,
      delay_penalty_count:        contractor.paid_over_due_payment_count,
    }

    render json: {
      success: true,
      contractor_status: contractor_status,
    }
  end

  # 入金(消し込み)処理
  def receive_payment
    contractor_id  = params[:contractor_id]
    payment_ymd    = params[:payment_ymd]
    payment_amount = params[:payment_amount].to_f
    comment        = params[:comment]
    is_exemption_late_charge = params[:no_delay_penalty].to_s == 'true' # 遅損金の免除
    installment_ids = params[:installment_ids]

    contractor = Contractor.find(contractor_id)

    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors: errors } if errors.present?

    error = nil
    ActiveRecord::Base.transaction do
      used_total_cashback = 0
      used_total_exceeded = 0
      remaining_input_amount = nil
      receive_amount_detail_data_arr = []
      receive_amount_history_id = nil
      if installment_ids.present?
        result = AppropriatePaymentToSelectedInstallments.new(contractor, payment_ymd, payment_amount, login_user,
          comment, is_exemption_late_charge, installment_ids: installment_ids).call
        error = result[:error]

        remaining_input_amount = payment_amount > 0 ? result[:remaining_input_amount] : nil
        receive_amount_detail_data_arr = result[:receive_amount_detail_data_arr]
        receive_amount_history_id = result[:receive_amount_history_id]
        # 業務エラーのチェック
        break if error.present?
      end
      break if remaining_input_amount.present? && remaining_input_amount == 0

      result = AppropriatePaymentToInstallments.new(
        contractor,
        payment_ymd,
        payment_amount,
        login_user,
        comment,
        is_exemption_late_charge,
        remaining_input_amount: remaining_input_amount || 0,
        receive_amount_history_id: receive_amount_history_id,
        receive_amount_detail_data_arr: receive_amount_detail_data_arr
      ).call
      error = result[:error]

      # 業務エラーのチェック
      break if error.present?

      # 排他チェック
      # ラグを減らすために消し込み後に実行
      # 消し込みでreceive_amount_historiesが作成されるので引数に1をプラスして比較する
      if contractor.receive_amount_histories.count != params.fetch(:receive_amount_history_count).to_i + 1
        raise ActiveRecord::StaleObjectError
      end
    end

    if error.blank?
      # メッセージとメールの送信
      SendReceivePaymentMessageAndEmail.new(contractor, payment_ymd, payment_amount).call

      render json: { success: true }
    else
      render json: { success: false, errors: [error] }
    end
  end

  # OrderDetailダイアログの表示
  def order_detail
    order = Order.find(params[:order_id])
    target_ymd = params[:target_ymd]

    render json: {
      success: true,
      order: format_jv_order_detail(order, target_ymd)
    }
  end

  # GET
  def receive_amount_history
    contractor = Contractor.find(params[:contractor_id])

    # ページングして取得
    receive_amount_histories, total_count =
      contractor.receive_amount_histories
      .includes(:create_user)
      .order(receive_ymd: :desc, created_at: :desc)
      .paging(params)

    render json: {
      success: true,
      receive_amount_histories: format_receive_amount_histories(receive_amount_histories),
      total_count: total_count,
      can_edit_comment: login_user.system_admin || login_user.md?
    }
  end

  def cancel_order
    result = CancelOrder.new(params[:order_id], login_user).call

    render json: result
  end

  def update_history_comment
    # 権限チェック　運用のJVユーザーの場合のみ使用可能
    errors = check_permission_errors(login_user.system_admin? || login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    contractor = Contractor.find(params[:contractor_id])
    receive_amount_history = contractor.receive_amount_histories.find(params[:receive_amount_history][:id])

    if receive_amount_history.update(update_history_comment_params)
      render json: { success: true }
    else
      render json: { success: false, errors: history.error_messages }
    end
  end

  # 一部入金済みをExceededへ移す処理
  def register_adjust_repayment
    installment_id = params[:installment_id]

    # 対象のinstallmentから取得
    installment =
      Installment.exclude_rescheduled_installments.inputed_date_installments.find(installment_id)

    errors = AdjustPaidOfInstallment.new.call(installment, login_user)

    if errors.present?
      render json: { success: false, errors: errors }
    else
      render json: { success: true }
    end
  end

  private

  def format_payments(contractor, payments, target_ymd, is_exemption_late_charge)
    # cashbackとexceededの減算額
    payment_subtractions =
      CalcPaymentSubtractions.new(contractor, target_ymd, is_exemption_late_charge).call

    payments.map do |payment|
      # installments
      installments = payment.installments.appropriation_sort.includes(:installment_histories)
      .map { |installment|
        # 遅損金の免除を考慮して算出
        late_charge = installment.calc_late_charge(target_ymd, is_exemption_late_charge)

        {
          id:                 installment.id,
          order:              {
            id:                installment.order.id,
            order_number:      installment.order.order_number,
            installment_count: installment.order.installment_count,
          },
          installment_number: installment.installment_number,
          paid_up_ymd:        installment.paid_up_ymd,
          # 支払い予定金額
          principal:   installment.principal.to_f,
          interest:    installment.interest.to_f,
          late_charge: late_charge,
          # 支払い済み金額
          paid_principal:   installment.paid_principal.to_f,
          paid_interest:    installment.paid_interest.to_f,
          paid_late_charge: installment.paid_late_charge.to_f,

          can_adjust_repayment: installment.can_adjust_repayment(login_user),
          lock_version:     installment.lock_version,
        }
      }

      payment_subtraction = payment_subtractions[payment.id]

      # payment
      {
        id:          payment.id,
        due_ymd:     payment.due_ymd,
        paid_up_ymd: payment.paid_up_ymd,
        # 支払い予定合計
        total_amount: payment.calc_total_amount(target_ymd, is_exemption_late_charge),
        # TODO 再約定した場合に支払った合計が多くなる場合があり、差分の表示がマイナスになる場合があるので確認
        # 支払い済み合計
        paid_total_amount: payment.paid_total_amount.to_f,

        cashback: payment.paid? ? payment_subtraction[:paid_cashback] : payment_subtraction[:cashback],
        exceeded: payment.paid? ? payment_subtraction[:paid_exceeded] : payment_subtraction[:exceeded],

        status:            payment.status_label,
        installments:      installments,
        lock_version:      payment.lock_version,
      }
    end
  end

  def format_evidence_list(evidences)
    evidences.map do |evidence|
      format_evidence(evidence)
    end
  end

  def format_evidence(evidence)
    {
      id:                evidence.id,
      evidence_number:   evidence.evidence_number,
      comment:           evidence.comment,
      checked_user: {
        id: evidence.checked_user_id,
        user_name: evidence.checked_user&.user_name,
      },
      create_user: {
        id: evidence.contractor_user_id,
        user_name: evidence.contractor_user.user_name,
      },
      checked_at:        evidence.checked_at,
      created_at:        evidence.created_at,
      updated_at:        evidence.updated_at,
      payment_image_url: evidence.payment_image.present? ? url_for(evidence.payment_image) : nil,
    }
  end

  def format_receive_amount_histories(receive_amount_histories)
    receive_amount_histories.map {|row|
       {
        id: row.id,
        receive_ymd: row.receive_ymd,
        receive_amount: row.receive_amount.to_f,
        comment: row.comment,
        no_delay_penalty_amount: row.exemption_late_charge.to_f,
        create_user: {
          id: row.create_user&.id,
          full_name: row.create_user&.full_name || '-',
        },
        created_at: row.created_at,
        lock_version: row.lock_version,
      }
    }
  end

  def update_history_comment_params
    params.require(:receive_amount_history).permit(:comment)
  end
end
