# frozen_string_literal: true

class Contractor::TopController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def credit_status
    contractor = login_user.contractor

    # ラジオボタンの選択値
    selected_dealer_type = params[:dealer_type]
    selected_dealer_id = params[:dealer_id]

    # 表示するDealer Type Limitを取得
    dealer_type_limits = contractor.latest_dealer_type_limits.map do |dealer_type_limit|
      target_dealer_limits = contractor.latest_dealer_limits.includes(:dealer)
        .where(dealers: {dealer_type: dealer_type_limit.dealer_type})

      dealers = target_dealer_limits.map {|dealer_limit|
        dealer = dealer_limit.dealer

        {
          id:                dealer.id,
          dealer_name:       dealer.dealer_name,
          limit_amount:      contractor.dealer_limit_amount(dealer),
          available_balance: contractor.dealer_available_balance(dealer)
        }
      }

      {
        dealer_type_label: dealer_type_limit.dealer_type_label,
        is_site_dealer: dealer_type_limit.site_dealer?,
        limit_amount: dealer_type_limit.limit_amount.to_f,
        available_balance: contractor.dealer_type_available_balance(dealer_type_limit.dealer_type),
        dealers: dealers
      }
    end

    credit_limit, remaining_principal, available_balance =
      if selected_dealer_type == "all"
        [
          contractor.credit_limit_amount,
          contractor.remaining_principal,
          contractor.available_balance,
        ]
      elsif selected_dealer_id.present?
        selected_dealer = Dealer.find(selected_dealer_id)
        [
          contractor.dealer_limit_amount(selected_dealer),
          contractor.dealer_remaining_principal(selected_dealer),
          contractor.dealer_available_balance(selected_dealer),
        ]
      else
        [
          contractor.dealer_type_limit_amount(selected_dealer_type),
          contractor.dealer_type_remaining_principal(selected_dealer_type),
          contractor.dealer_type_available_balance(selected_dealer_type),
        ]
      end

    credit_status = {
      contractor_id:              contractor.id,
      th_company_name:            contractor.th_company_name,
      en_company_name:            contractor.en_company_name,
      credit_limit:               credit_limit,
      used_amount:                remaining_principal,
      available_balance:          available_balance,
      cashbacks_for_next_payment: contractor.cashback_amount,
      cashback_use_ymd:           contractor.cashback_use_ymd,
      exceeded_amount:            contractor.pool_amount.to_f,
      dealer_type_limits:         dealer_type_limits,
    }

    render json: { success: true, credit_status: credit_status }
  end

  def payment
    # next_payment
    # 遅延分にかかわらず、現在から見て次の支払日の日付＆金額を表示。
    # ただし、予定分ではなく実績分（部分的に入金された場合、その時点で反映される）。

    # over_due_amount
    # Late Chargeの合計、ではなく、遅延分（Overdueとなっている）の、
    # 遅延しているPrincipal&Interest&Late Charge（つまり遅れている全額）を表示。

    contractor = login_user.contractor
    next_payment = contractor.next_payment

    # CashbackとExceededを考慮した遅延支払額と次回支払い残金を取得
    over_due_amount = contractor.calc_over_due_amount

    # next_paymentを整形
    next_payment_info = next_payment.present? ? format_next_payment(contractor, next_payment) : nil

    render json: {
      success: true,
      payment: {
        contractor_id:   contractor.id,
        checking_payment: contractor.check_payment,
        next_payment:    next_payment_info,
        exist_over_due_amount: contractor.payments.over_due.exists?,
        over_due_amount: over_due_amount
      }
    }
  end

  def projects
    contractor = login_user.contractor
    target_projects = login_user.contractor.projects.eager_load(:installments).opened.order(:id)

    projects = target_projects.map {|project|
      target_orders = project.orders.payable_orders.inputed_ymd.where(contractor: contractor)

      # 対象のinstallmentsを取得
      target_installments = Installment.where(order: target_orders)

      next if target_installments.blank?

      # 直近のDueDateを取得
      latest_due_ymd = target_installments.order(:due_ymd).first.due_ymd

      # 直近DueDateのinstallmentsを取得
      latest_due_installments = target_installments.where(due_ymd: latest_due_ymd)

      # 直近の支払額
      remaining_balance = latest_due_installments.sum(&:remaining_balance)

      # 全体の遅損金
      total_late_charge = target_installments.sum(&:calc_remaining_late_charge)

      {
        id: project.id,
        project_code: project.project_code,
        project_name: project.project_name,
        project_manager: {
            id: project.project_manager.id,
            project_manager_name: project.project_manager.project_manager_name
        },
        status: project.status_label,
        next_payment: {
            date: latest_due_ymd,
            amount: remaining_balance
        },
        over_due_amount: total_late_charge
      }
    }.compact

    render json: {
      success: true,
      projects: projects,
    }
  end

  def qr_code
    contractor = login_user.contractor
    qr_code_image_url = contractor.qr_code_image.attached? ? url_for(contractor.qr_code_image) : nil

    render json: {
      success: true,
      qr_code_image_url: qr_code_image_url,
    }
  end

  private
  # 次回支払い情報
  def format_next_payment(contractor, next_payment)
    # cashbackとexceededを引いたpayments
    payment_subtractions = contractor.calc_payment_subtractions
    remaining_amount = next_payment.remaining_balance - payment_subtractions[next_payment.id][:total]

    # 約定日と支払い残金
    {
      id: next_payment.id,
      status: next_payment.status,
      date: next_payment.due_ymd,
      amount: remaining_amount.round(2),
    }
  end
end
