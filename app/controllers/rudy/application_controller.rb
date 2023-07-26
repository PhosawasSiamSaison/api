# frozen_string_literal: true

class Rudy::ApplicationController < ActionController::API
  before_action :output_log
  before_action :check_auth

  class AuthFailed < StandardError; end
  class ValidationError < StandardError; end
  class NoCaseDemo < StandardError; end

  rescue_from Exception, with: :catch_exception
  rescue_from AuthFailed, with: :auth_failed
  rescue_from ValidationError, with: :validation_error
  rescue_from NoCaseDemo, with: :no_case_demo

  def catch_exception exception
    logger.fatal exception.inspect
    render json: { result: 'NG', error: 'unexpected', error_detail: exception.inspect }
  end

  def auth_failed exception
    logger.info exception.inspect
    render json: { result: 'NG', error: 'auth_failed' }
  end

  def validation_error error_type
    logger.info "RUDY ValidationError: #{error_type}"
    render json: { result: 'NG', error: error_type }
  end

  def no_case_demo exception
    logger.info exception.inspect
    render json: { result: 'NG', error: 'unexpected', error_detail: '-- error detail sample --' }
  end

  def output_log
    Rails.logger.info({
      "logtype": "API_REQUEST_BY_RUDY",
      "path": request.path,
      "params": request.params,
    }.to_json)
  end

  # オーダー作成の共通エラーチェック
  def common_order_error_check(exclude_items: [])
    purchase_amount = params[:amount]

    # 金額チェック
    return 'amount is not valid' if invalid_amount?(purchase_amount)

    # Contractorチェック
    contractor = Contractor.after_registration.find_by(tax_id: params[:tax_id])
    return 'contractor_not_found'   if contractor.blank?
    return 'contractor_unavailable' if !contractor.active?

    # Dealerチェック
    dealer = Dealer.find_by(dealer_code: params[:dealer_code])
    return 'dealer_not_found' if dealer.blank?

    # Second Dealer のチェック
    if params[:second_dealer_code].present?
      second_dealer_code   = params[:second_dealer_code]
      second_dealer_amount = params[:second_dealer_amount]
      second_dealer = Dealer.find_by(dealer_code: second_dealer_code)

      return 'second_dealer_not_found' if second_dealer.blank?

      return 'invalid_second_dealer' if dealer == second_dealer

      if invalid_amount?(second_dealer_amount) || purchase_amount.to_f < second_dealer_amount.to_f
        return 'invalid_second_dealer_amount'
      end
    end

    # 日付チェック
    return 'invalid_purchase_date' if !valid_ymd?(params[:purchase_date])

    # 商品チェック
    if !exclude_items.include?(:product) && Product.find_by(product_key: params[:product_id]).blank?
      return 'invalid_product'
    end

    return ''
  end

  def create_site_error_check(on_create, is_project: false)
    type = is_project ? 'project' : 'site'

    tax_id            = params[:tax_id]
    site_code         = params["#{type}_code".to_sym]
    site_name         = params["#{type}_name".to_sym]
    site_credit_limit = params["#{type}_credit_limit"].to_f
    dealer_code       = params[:dealer_code]
    auth_token        = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    if on_create
      contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
      raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?
    end

    exist_site_code =
      Site.exists?(site_code: site_code) || ProjectPhaseSite.exists?(site_code: site_code)
    raise(ValidationError, "duplicate_#{type}_code") if exist_site_code

    site = Site.new(site_code: site_code, site_name: site_name)
    raise(ValidationError, "too_long_#{type}_code") if site.too_long?(:site_code)
    raise(ValidationError, "too_long_#{type}_name") if site.too_long?(:site_name)

    dealer = Dealer.find_by(dealer_code: dealer_code)
    raise(ValidationError, 'dealer_not_found') if dealer.blank?

    # DealerTypeのチェック
    if is_project
      raise(ValidationError, 'unmatch_dealer_type') if !dealer.project_group?
    else
      raise(ValidationError, 'unmatch_dealer_type') if !dealer.cpac_group?
    end

    # Limit設定チェック
    if !contractor.dealer_without_limit_setting?(dealer)
      raise(ValidationError, 'dealer_without_limit_setting')
    end

    error = nil
    result = {}

    if contractor.over_dealer_limit?(dealer, site_credit_limit)
      logger.info "RUDY ValidationError: over_dealer_limit"

      error = true
      result = {
        result: 'NG',
        error: 'over_dealer_limit',
        available_balance: contractor.dealer_available_balance(dealer),
      }
    elsif contractor.over_dealer_type_limit?(dealer.dealer_type, site_credit_limit)
      logger.info "RUDY ValidationError: over_dealer_type_limit"

      error = true
      result = {
        result: 'NG',
        error: 'over_dealer_type_limit',
        available_balance: contractor.dealer_type_available_balance(dealer.dealer_type),
      }

    # Credit Limit 上限チェック
    elsif contractor.over_credit_limit?(site_credit_limit)
      logger.info "RUDY ValidationError: over_credit_limit"

      error = true
      result = {
        result: 'NG',
        error: 'over_credit_limit',
        available_balance: contractor.available_balance
      }
    end

    [error, result]
  end

  def update_site_error_check(on_update, is_project: false)
    type = is_project ? 'project' : 'site'

    tax_id                = params[:tax_id]
    site_code             = params["#{type}_code"]
    new_site_code         = params["new_#{type}_code"]
    site_name             = params["#{type}_name"]
    new_site_credit_limit = params["#{type}_credit_limit"].to_f
    dealer_code           = params[:dealer_code]
    auth_token            = params[:auth_token]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    if on_update
      contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
      raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?
    end

    site = is_project ?
      contractor.sites.is_projects.find_by(site_code: site_code) :
      contractor.sites.not_projects.find_by(site_code: site_code)

    raise(ValidationError, "#{type}_not_found") if site.blank?
    raise(ValidationError, "#{type}_closed")    if site.closed?
    raise(ValidationError, 'under_used_amount') if new_site_credit_limit < site.remaining_principal

    # Site Codeの変更がある場合
    if new_site_code.present? && new_site_code != site_code
      new_site = Site.find_by(site_code: new_site_code)
      raise(ValidationError, "duplicate_#{type}_code") if new_site.present?

      # すでにオーダーがある場合はSite Codeは変更不可
      raise(ValidationError, 'already_ordered') if site.orders.exclude_canceled.present?

      raise(ValidationError, "too_long_#{type}_code") if Site.new(site_code: new_site_code).too_long?(:site_code)
    end

    raise(ValidationError, "too_long_#{type}_name") if Site.new(site_name: site_name).too_long?(:site_name)

    # Dealerの変更は不可
    dealer = site.dealer
    raise(ValidationError, 'dealer_cannot_be_changed') if dealer.dealer_code != dealer_code


    # Limit設定チェック
    if !contractor.dealer_without_limit_setting?(dealer)
      raise(ValidationError, 'dealer_without_limit_setting')
    end

    # 現在と新しいリミットの差分を算出
    site_credit_limit_diff = [new_site_credit_limit - site.site_credit_limit, 0].max.round(2).to_f

    error = nil
    result = {}

    # 新しい Limitが現在よりも増えていた場合 Limitをチェックする
    if site_credit_limit_diff > 0
      if contractor.over_dealer_limit?(dealer, site_credit_limit_diff)
        logger.info "RUDY ValidationError: over_dealer_limit"

        error = true
        result = {
          result: 'NG',
          error: 'over_dealer_limit',
          available_balance: (contractor.dealer_available_balance(dealer)).round(2).to_f
        }
      elsif contractor.over_dealer_type_limit?(dealer.dealer_type, site_credit_limit_diff)
        logger.info "RUDY ValidationError: over_dealer_type_limit"

        error = true
        result = {
          result: 'NG',
          error: 'over_dealer_type_limit',
          available_balance: (contractor.dealer_type_available_balance(dealer)).round(2).to_f
        }
      elsif contractor.over_credit_limit?(site_credit_limit_diff)
        logger.info "RUDY ValidationError: over_credit_limit"

        error = true
        result = {
          result: 'NG',
          error: 'over_credit_limit',
          available_balance: contractor.available_balance
        }
      end
    end

    [error, result]
  end

  private
  def invalid_amount?(amount)
    return true if amount.nil?

    return true if !is_number?(amount)

    amount.to_f < 0
  end

  def is_number?(amount)
    is_integer?(amount) || is_float?(amount)
  end

  def is_integer?(amount)
    Integer(amount)
    true
  rescue ArgumentError
    false
  end

  def is_float?(amount)
    Float(amount)
    true
  rescue ArgumentError
    false
  end

  # 日付の有効チェック
  def valid_ymd?(ymd)
    ymd = ymd.to_s

    return false if ymd.length != 8
    return false if !ymd.match(/\d{8}/)

    begin
      Date.parse(ymd, '%Y%m%d')
    rescue Exception => e
      return false
    end

    true
  end

  def check_auth
    request_from_ssa? ? check_auth_for_ssa : check_auth_for_rudy
  end

  def check_auth_for_rudy
    # Railsの環境毎のRUDY API 認証Key
    setting_key = JvService::Application.config.try(:rudy_api_auth_key)
    demo_key = JvService::Application.config.try(:rudy_demo_api_auth_key)

    raise AuthFailed if setting_key != req_bearer && demo_key != req_bearer
  end

  def check_auth_for_ssa
    setting_key = JvService::Application.config.try(:ssa_api_auth_key)

    raise AuthFailed if setting_key != req_bearer
  end

  def request_from_ssa?
    request.path.include?('/ssa/')
  end

  def req_bearer
    request.headers.fetch(:HTTP_AUTHORIZATION, '').sub('Bearer', '').strip
  end

  def get_demo_bearer_token?
    # デモ用のトークンを取得
    demo_key = JvService::Application.config.try(:rudy_demo_api_auth_key)

    auth_key = request.headers.fetch(:HTTP_AUTHORIZATION, '').sub('Bearer', '').strip

    demo_key == auth_key
  end

  def too_long?(model, column)
    model.valid?
    model.errors.details[column.to_sym].any?{|col| col[:error] == :too_long}
  end

  def check_order_error(order)
    # order_type 文字数チェック
    return 'too_long_order_type' if too_long?(order, :order_type)

    # region 文字数チェック
    return 'too_long_region' if too_long?(order, :region)

    nil
  end
end
