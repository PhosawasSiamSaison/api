# frozen_string_literal: true

class Jv::RepaymentListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    payments, total_count = SearchRepaymentList.new(params).call

    render json: {
      success: true,
      payments: format_payments(payments),
      total_count: total_count
    }
  end

  # セレクトボックスの一覧
  def status_list
    list = [:next_due, :not_due_yet].map do |key|
      {
        code: key,
        label: I18n.t("enum.payment.status.#{key}")
      }
    end

    # 先頭に追加
    list.unshift({ code: 'all', label: 'ALL'})

    render json: { success: true, list: list }
  end

  private
  def format_payments(payments)
    payments.map do |payment|
      contractor = payment.contractor
      installments = payment.include_no_input_date_installments.appropriation_sort

      # Payment
      {
        id: payment.id,
        due_ymd: payment.due_ymd,
        total_amount: payment.total_amount.to_f,
        paid_total_amount: payment.paid_total_amount.to_f,
        status: payment.status_label,

        # Contractor
        contractor: {
          id: contractor.id,
          tax_id: contractor.tax_id,
          th_company_name: contractor.th_company_name,
          en_company_name: contractor.en_company_name
        },

        # Installments
        installments: installments.map { |installment|
          order = installment.order

          {
            id: installment.id,
            order: {
              id: order.id,
              order_number: order.order_number,
              installment_count: order.installment_count,
            },
            installment_number: installment.installment_number,
            paid_up_ymd: installment.paid_up_ymd,

            principal:   installment.principal.to_f,
            interest:    installment.interest.to_f,
            late_charge: installment.paid_late_charge.to_f,

            paid_principal:   installment.paid_principal.to_f,
            paid_interest:    installment.paid_interest.to_f,
            paid_late_charge: installment.paid_late_charge.to_f,

            lock_version:     installment.lock_version,
          }
        },
        lock_version:      payment.lock_version,
      }
    end
  end
end
