# frozen_string_literal: true

class Rudy::SetOrderInputDateController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    tax_id = params[:tax_id]
    dealer_code = params[:dealer_code]
    order_number = params[:order_number]
    input_date = params[:input_date]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    dealer = Dealer.find_by(dealer_code: dealer_code)

    order = Order.find_by(dealer: dealer, order_number: order_number)
    raise(ValidationError, 'order_not_found') if order.blank?
    raise(ValidationError, 'already_canceled_order')  if order.canceled?
    raise(ValidationError, 'already_processed_order') if order.input_ymd.present?

    input_ymd = Date.parse(input_date, '%Y%m%d').strftime('%Y%m%d')

    # 業務日以外はエラー
    raise(ValidationError, 'input_date_not_today') if input_ymd != BusinessDay.today_ymd

    # Inactiveの場合は購入日が１ヶ月以内ならInput可能
    raise(ValidationError, 'not_allowed_to_input') if contractor.inactive? && !BusinessDay.allowed_to_input_date?(order.purchase_ymd)

    # Set Input Date
    ActiveRecord::Base.transaction do
      order.update!(
        input_ymd: input_ymd,
        input_ymd_updated_at: Time.now,
      )

      order.payments.paid.each do |payment|
        payment.rollback_paid_status
        payment.save!
      end
    end

    # 自動消し込み(メール送信があるのでトランザクションの外で処理をする)
    AutoRepaymentExceededAndCashback.new.call(contractor) unless order.belongs_to_project_finance? # ProjectFinanceは除外する

    render json: { result: 'OK' }
  end

  private
  def render_demo_response
    tax_id = params[:tax_id]
    order_number = params[:order_number]
    input_date = params[:input_date]

    # Success
    if tax_id == '1234567890111' && order_number == '1234500000'
      return render json: { result: "OK" }
    end

    # Error : already_processed_order
    raise(ValidationError, 'already_processed_order') if tax_id == '1234567890111' && order_number == '1111100000'

    # Error : contractor_not_found
    raise(ValidationError, 'contractor_not_found') if tax_id == '1234567890000' && order_number == '1234500000'

    # Error : order_not_found
    raise(ValidationError, 'order_not_found') if tax_id == '1234567890111' && order_number == '0000000000'

    # 一致しない
    raise NoCaseDemo
  end
end
