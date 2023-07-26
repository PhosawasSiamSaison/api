# frozen_string_literal: true

class Jv::RepaymentHistoryController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    payments, total_count = Payment.search_repayment_history(params)

    render json: {
      success: true,
      payments: format_payments(payments),
      total_count: total_count
    }
  end

  def order_detail
    order = Order.find(params[:order_id])

    render json: {
      success: true,
      order: format_jv_order_detail(order)
    }
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
        paid_up_ymd: payment.paid_up_ymd,
        total_amount: payment.total_amount.to_f,
        paid_total_amount: payment.paid_total_amount.to_f,
        cashback: payment.paid_cashback.to_f,
        exceeded: payment.paid_exceeded.to_f,

        over_due_payment: payment.due_ymd < payment.paid_up_ymd,

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
            late_charge: installment.exist_exemption_late_charge ? 0.0 : installment.paid_late_charge.to_f,

            paid_principal:   installment.paid_principal.to_f,
            paid_interest:    installment.paid_interest.to_f,
            paid_late_charge: installment.paid_late_charge.to_f,

            # InputDateなしのinstallmentも一応表示するのでその場合は false を返す
            over_due_installment: installment.paid_up_ymd.present? ?
              installment.due_ymd < installment.paid_up_ymd : false,

            lock_version:     installment.lock_version,
          }
        },
        lock_version:      payment.lock_version,
      }
    end
  end
end
