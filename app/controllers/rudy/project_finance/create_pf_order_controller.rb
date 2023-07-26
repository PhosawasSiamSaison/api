# frozen_string_literal: true

class Rudy::ProjectFinance::CreatePfOrderController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    tax_id               = params[:tax_id]
    site_code            = params[:site_code]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    amount               = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax]
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]


    # オーダーで共通のエラーチェック
    error = common_order_error_check()
    raise(ValidationError, error) if error.present?

    # 金額チェック
    if invalid_amount?(amount_without_tax)
      raise(ValidationError, 'amount_without_tax is not valid')
    end

    dealer = Dealer.find_by(dealer_code: dealer_code)

    # SecondDealer取得
    second_dealer = nil
    if second_dealer_code.present?
      second_dealer = Dealer.find_by(dealer_code: second_dealer_code)
    end

    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    project_phase_site = contractor.project_phase_sites.find_by(site_code: site_code)

    # Siteチェック
    site = contractor.sites.find_by(site_code: site_code)
    raise(ValidationError, 'site_not_found') if site.blank? && project_phase_site.blank?
    raise(ValidationError, 'site_not_tied_with_phase') if site.present? && project_phase_site.blank?
    raise(ValidationError, 'site_closed') if project_phase_site.closed?

    # PhaseのStatusチェック
    raise(ValidationError, 'PHASE_NOT_OPEN') unless project_phase_site.project_phase.opened?

    # Available Settingのチェック
    product = Product.find_by(product_key: product_key)
    project_manager = project_phase_site.project.project_manager # PFの判定はPMのdealer_typeを使用する
    if !contractor.available_purchase?(project_manager.dealer_type, product)
      raise(ValidationError, 'unavailable_purchase_setting')
    end

    # 重複オーダーチェック
    duplicate_order = Order.exclude_canceled.find_by(dealer: dealer, order_number: order_number)
    raise(ValidationError, 'duplicate_order') if duplicate_order.present?


    # Site Limit 上限チェック
    if project_phase_site.over_site_limit?(amount)
      logger.info "RUDY ValidationError: over_site_limit"

      return render json: {
        result: 'NG',
        error: 'over_site_limit',
        available_balance: project_phase_site.available_balance,
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
      purchase_amount: amount,
      amount_without_tax: amount_without_tax,
      second_dealer_amount: second_dealer_amount,
      project_phase_site: project_phase_site,
      region: region,
      rudy_purchase_ymd: rudy_purchase_ymd
    )

    # Orderモデルでのエラーチェック
    rudy_error = check_order_error(order)
    raise(ValidationError, rudy_error) if rudy_error.present?

    ActiveRecord::Base.transaction do
      CreateProjectFinanceOrder.new.call(order)

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
