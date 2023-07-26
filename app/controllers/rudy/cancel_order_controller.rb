# frozen_string_literal: true

class Rudy::CancelOrderController < Rudy::ApplicationController
  def call
    tax_id       = params.fetch(:tax_id)
    order_number = params.fetch(:order_number)
    dealer_code  = params.fetch(:dealer_code)

    # バリデーションチェック
    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    dealer = Dealer.find_by(dealer_code: dealer_code)
    raise(ValidationError, 'dealer_not_found') if dealer.blank?

    order = contractor.include_pf_orders.find_by(order_number: order_number, dealer: dealer)
    raise(ValidationError, 'order_not_found') if order.blank?

    # 当日のみキャンセル可能
    raise(ValidationError, 'input_date_not_today') if order.input_ymd.present? && order.input_ymd != BusinessDay.today_ymd

    # キャンセル処理
    result = CancelOrder.new(order.id, nil, on_rudy: true).call
    raise(ValidationError, result[:error]) unless result[:success]

    render json: { result: "OK" }
  end
end
