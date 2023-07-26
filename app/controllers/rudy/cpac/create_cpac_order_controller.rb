# frozen_string_literal: true

class Rudy::Cpac::CreateCpacOrderController < Rudy::ApplicationController
  def call
    # return render_demo_response if get_demo_bearer_token?

    tax_id               = params[:tax_id]
    site_code            = params[:site_code]
    order_type           = params[:order_type]
    order_number         = params[:order_number]
    product_key          = params[:product_id]
    dealer_code          = params[:dealer_code]
    rudy_purchase_ymd    = params[:purchase_date]
    amount               = params[:amount].to_f
    amount_without_tax   = params[:amount_without_tax].to_f
    second_dealer_code   = params[:second_dealer_code]
    second_dealer_amount = params[:second_dealer_amount].to_f
    region               = params[:region]
    recreate             = params[:recreate].to_s == "true" # true以外はfalseにする
    bill_date            = params.fetch(:bill_date, nil)

    # オーダーで共通のエラーチェック
    error = common_order_error_check
    raise(ValidationError, error) if error.present?

    # bill_dateのチェック
    raise(ValidationError, 'invalid_bill_date') if bill_date.nil?
    raise(ValidationError, 'too_long_bill_date') if bill_date.length > 15

    # 金額チェック
    if invalid_amount?(params[:amount_without_tax])
      raise(ValidationError, 'amount_without_tax is not valid')
    end

    # Dealerチェック
    dealer = Dealer.find_by(dealer_code: dealer_code)
    raise(ValidationError, 'unmatch_dealer_type') if !dealer.cpac_group?

    # SecondDealer取得
    second_dealer = nil
    if second_dealer_code.present?
      second_dealer = Dealer.find_by(dealer_code: second_dealer_code)
    end

    # Siteチェック
    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    site = contractor.sites.not_projects.find_by(site_code: site_code)
    raise(ValidationError, 'site_not_found') if site.blank?
    raise(ValidationError, 'site_closed')    if site.closed?

    # オーダーのチェック(通常の場合はDB制約でチェックする)
    if recreate
      # Order作り直しのバリデーション
      current_order = Order.find_by(order_number: order_number, dealer: dealer,
        bill_date: bill_date, site: site)

      raise(ValidationError, 'order_not_found')        if current_order.blank?
      raise(ValidationError, 'already_canceled_order') if current_order.canceled? # キャンセル済みは通常オーダーになる想定
      raise(ValidationError, 'already_paid_order')     if current_order.paid_total_amount > 0
    end


    # Limit設定チェック
    if !contractor.dealer_without_limit_setting?(dealer)
      raise(ValidationError, 'dealer_without_limit_setting')
    end

    # Available設定チェック(Limit設定後に利用可能なのでLimit設定チェックの後に実行する)
    product = Product.find_by(product_key: product_key)
    if !contractor.available_purchase?(dealer.dealer_type, product)
      raise(ValidationError, 'unavailable_purchase_setting')
    end

    # 規約同意チェック
    # auth_tokenがないので(ContractorUserを特定できないので)規約のチェックなし

    # Site Limit 上限チェック
    if site.over_site_credit_limit?(amount, current_order&.purchase_amount.to_f)
      logger.info "RUDY ValidationError: over_site_credit_limit"

      # 作り直しの場合は現在の購入金額を含めないのでその分の枠を広げる
      site_available_balance =
        (site.available_balance + current_order&.purchase_amount.to_f).round(2).to_f

      return render json: {
        result: 'NG',
        error: 'over_site_credit_limit',
        site_available_balance: site_available_balance,
      }
    end

    order = Order.new(
      contractor: contractor,
      order_type: order_type,
      order_number: order_number,
      dealer: dealer,
      second_dealer: second_dealer,
      product: product,
      installment_count: product.number_of_installments,
      purchase_ymd: BusinessDay.today_ymd,
      purchase_amount: amount,
      input_ymd: BusinessDay.today_ymd,
      input_ymd_updated_at: Time.now,
      amount_without_tax: amount_without_tax,
      second_dealer_amount: second_dealer_amount,
      site: site,
      region: region,
      rudy_purchase_ymd: rudy_purchase_ymd,
      bill_date: bill_date,
    )

    # モデルでのエラーチェック
    rudy_error = check_order_error(order)
    raise(ValidationError, rudy_error) if rudy_error.present?

    new_order = nil
    ActiveRecord::Base.transaction do
      # DBの一意制約の兼ね合いでオーダー作成前に実行する
      if recreate
        # 作り直す場合は今のOrderを削除する
        current_order.update!(deleted: true, uniq_check_flg: nil)
      end

      new_order = CreateOrder.new.call(order)

      # remove_from_paymentの処理のためにオーダー作成後に実行する
      if recreate
        # 紐づくPaymentとInstallmentを調整
        current_order.installments.each do |installment|
          installment.update!(deleted: true)
          installment.remove_from_payment
        end
      end
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      Rails.logger.info(e)
      raise(ValidationError, 'duplicate_order')

    # 以下のエラーは重複であるなしに関わらず、同じContractorのorderが高速で連続で来た場合に起こりうるエラーのため
    rescue ActiveRecord::StaleObjectError => e
      Rails.logger.info(e)
      raise(ValidationError, 'too_short_interval')
    end

    # SMS送信
    contractor.contractor_users.sms_targets.each do |contractor_user|
      SendMessage.send_create_cpac_order(contractor_user, site, new_order)
    end

    # 自動消し込み(メール送信があるのでトランザクションの外で処理をする)
    AutoRepaymentExceededAndCashback.new.call(contractor)

    return render json: {
      result: 'OK'
    }
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
