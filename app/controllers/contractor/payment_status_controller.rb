# frozen_string_literal: true

class Contractor::PaymentStatusController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def payments
    contractor = login_user.contractor
    payments = contractor.payments.search_contractor_payments(params)

    render json: {
      success: true,
      checking_payment: contractor.check_payment,
      # Switchアイコンの表示で使用
      allowed_change_products: contractor.allowed_change_products.ids,
      payments: format_payments(contractor, payments)
    }
  end

  private
  def format_payments(contractor, payments)
    calc_payment_subtractions = CalcPaymentSubtractions.new(contractor).call

    formatted_payments = payments.map do |payment|
      # exceededとcashbackの減算額を算出
      subtraction = calc_payment_subtractions[payment.id][:total]

      # 支払い残金からexceededとcashbackを引いた値を算出
      remaining_balance = (payment.remaining_balance - subtraction).round(2)

      {
        id: payment.id,
        due_ymd: payment.due_ymd,
        paid_up_ymd: payment.paid_up_ymd,
        total_amount: remaining_balance,
        paid_total_amount: payment.paid_total_amount.to_f,
        can_apply_change_product: payment.has_can_apply_change_product_order?,
        can_change_product: payment.has_can_change_product_order?,
        status: payment.status,
      }
    end

    # nil を削除
    formatted_payments.compact
  end
end