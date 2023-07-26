# frozen_string_literal: true

class Rudy::CreateOrderController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    tax_id               = params[:tax_id]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    purchase_amount      = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    auth_token           = params[:auth_token]


    # オーダーで共通のエラーチェック
    error = common_order_error_check
    raise(ValidationError, error) if error.present?

    # 金額チェック
    if amount_without_tax.present? && invalid_amount?(amount_without_tax)
      raise(ValidationError, 'amount_without_tax is not valid')
    end

    # ContractorUserチェック
    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
    raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

    # Dealerチェック
    dealer = Dealer.find_by(dealer_code: dealer_code)
    raise(ValidationError, 'unmatch_dealer_type') if dealer.site_dealer?

    # SecondDealer取得
    second_dealer = nil
    if second_dealer_code.present?
      second_dealer = Dealer.find_by(dealer_code: second_dealer_code)
    end

    # 重複オーダーチェック
    duplicate_order = Order.exclude_canceled.find_by(dealer: dealer, order_number: order_number)
    raise(ValidationError, 'duplicate_order') if duplicate_order.present?

    # Limit設定チェック
    if !contractor.dealer_without_limit_setting?(dealer)
      raise(ValidationError, 'dealer_without_limit_setting')
    end

    # Available設定チェック(Limit設定後に利用可能なのでLimit設定チェックの後に実行する)
    product = Product.find_by(product_key: product_key)
    if !contractor.available_purchase?(dealer.dealer_type, product)
      raise(ValidationError, 'unavailable_purchase_setting')
    end

    # PDPA同意チェック
    if !contractor_user.agreed_latest_pdpa?
      raise(ValidationError, 'not_pdpa_agreed')
    end

    # 規約同意チェック
    if contractor_user.not_agree_or_updated_terms_of_service?(dealer.dealer_type)
      raise(ValidationError, 'not_agreed')
    end

    # Dealer Limit上限チェック
    if contractor.over_dealer_limit?(dealer, purchase_amount)
      logger.info "RUDY ValidationError: over_dealer_limit"

      return render json: {
        result: 'NG',
        error: 'over_dealer_limit',
        available_balance: contractor.dealer_available_balance(dealer)
      }
    end

    # Dealer Type Limit　上限チェック
    if contractor.over_dealer_type_limit?(dealer.dealer_type, purchase_amount)
      logger.info "RUDY ValidationError: over_dealer_type_limit"

      return render json: {
        result: 'NG',
        error: 'over_dealer_type_limit',
        available_balance: contractor.dealer_type_available_balance(dealer.dealer_type)
      }
    end

    # Credit Limit 上限チェック
    if contractor.over_credit_limit?(purchase_amount)
      logger.info "RUDY ValidationError: over_credit_limit"

      return render json: {
        result: 'NG',
        error: 'over_credit_limit',
        available_balance: contractor.available_balance
      }
    end

    order = Order.new(
      contractor: contractor,
      order_number: order_number,
      dealer: dealer,
      second_dealer: second_dealer,
      product: product,
      installment_count: product.number_of_installments,
      purchase_ymd: BusinessDay.today_ymd,
      purchase_amount: purchase_amount,
      amount_without_tax: amount_without_tax,
      second_dealer_amount: second_dealer_amount,
      order_user: contractor_user,
      region: region,
      rudy_purchase_ymd: rudy_purchase_ymd
    )

    # Orderモデルでのエラーチェック
    rudy_error = check_order_error(order)
    raise(ValidationError, rudy_error) if rudy_error.present?

    ActiveRecord::Base.transaction do
      CreateOrder.new.call(order)

      # contractor_user.update!(rudy_auth_token: nil)

      # 成功
      return render json: {
        result: 'OK',
        header_text: RudyApiSetting.response_header_text,
        text: RudyApiSetting.response_text,
      }
    end
  end

  private
  def render_demo_response
    tax_id = params[:tax_id]
    order_number = params[:order_number]
    product_id = params[:product_id]
    auth_token = params[:auth_token]

    # Success
    if tax_id == '1234567890111' && order_number == '1234500000'
      return render json: {
        result: "OK",
        header_text: "กรุณาติดต่อ SAISON",
        text: "ในกรณีที่คุณลืมรหัสผ่านกรุณาติดต่อ SAISON เพื่อขอรหัสผ่านใหม่ในการเข้าระบบ\nโทร: 099-4444 4455 (** ติดต่อได้ตลอดชั่วโมง **)"
      }
    end

    # Error : duplicate_order
    raise(ValidationError, 'duplicate_order') if tax_id == '1234567890111' && order_number == '1111100000'

    # Error : contractor_not_found
    raise(ValidationError, 'contractor_not_found') if tax_id == '1234567890000' && order_number == '1234500000'

    # Error : order_not_found
    raise(ValidationError, 'order_not_found') if tax_id == '1234567890111' && order_number == '0000000000'

    # Error : contractor_unavailable
    raise(ValidationError, 'contractor_unavailable') if tax_id == '1234567890222' && order_number == '1234500000'

    # Error : unmatch_dealer_type
    raise(ValidationError, 'unmatch_dealer_type') if tax_id == '1234567890333' && order_number == '1234500000'

    # Error : over_credit_limit
    if tax_id == '1234567890333' && order_number == '1234500000'
      return render json: {
        result: "NG",
        error: 'over_credit_limit',
        available_balance: 10000.0
      }
    end

    # Error : invalid_product
    raise(ValidationError, 'invalid_product') if tax_id == '1234567890111' && order_number == '1234600000'

    # Error : unverified
    raise(ValidationError, 'unverified') if tax_id == '1234567890111' && order_number == '1234700000'

    # Error : dealer_not_found
    raise(ValidationError, 'dealer_not_found') if tax_id == '1234567890111' && order_number == '1234800000'

    # 一致しない
    raise NoCaseDemo
  end
end
