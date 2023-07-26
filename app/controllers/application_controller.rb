# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ErrorInfoModule, ImageModule

  before_action :set_locale
  before_action :check_front_version
  after_action :log_response

  class AuthFailed < StandardError; end
  class RudyError < StandardError; end
  class UnmatchFrontVersion < StandardError; end
  class UnmatchPdpaVersion < StandardError; end
  class UnmatchTermsOfService < StandardError; end
  class UnexpectedCase < StandardError; end

  rescue_from Exception, with: :catch_exception
  rescue_from AuthFailed, with: :auth_failed
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::StaleObjectError, with: :stale_object_error
  rescue_from RudyError, with: :rudy_error
  rescue_from UnmatchFrontVersion, with: :unmatch_front_version
  rescue_from UnmatchPdpaVersion, with: :unmatch_pdpa_version
  rescue_from UnmatchTermsOfService, with: :unmatch_terms_of_service
  rescue_from UnexpectedCase, with: :unexpected_case

  def log_response
    return unless Rails.env.development?

    # ダウンロード系は表示しない
    return if request.fullpath.include?('/download_')

    pp JSON.parse(response.body)
  end

  def catch_exception(exception)
    # DBエラーを判定させる
    if mysql_error? exception
      mysql_error(exception)
    else
      system_error(exception)
    end
  end

  def system_error(exception)
    pp exception.backtrace if Rails.env.development?

    logger.fatal exception.inspect
    render json: { success: false, error: "system_error", error_detail: exception.message }
  end

  def mysql_error(exception)
    logger.info exception.inspect
    render json: { success: false, error: "validation_error", error_detail: exception.cause }
  end

  def unexpected_case(message)
    raise("UnexpectedCase. #{message}")
  end

  # 認証エラー
  def auth_failed(exception)
    logger.info exception.inspect
    render json: { success: false, error: "auth_failed" }
  end

  # レコードが見つからない
  def record_not_found(exception)
    logger.info exception.inspect
    render json: { success: false, error: "record_not_found", error_detail: exception.message }
  end

  # 更新時のlock_versionが古い
  def stale_object_error(exception)
    logger.info exception.inspect

    render json: {
      success: false,
      errors: [I18n.t("error_message.stale_object_error")]
    }
  end

  def auth_user
    auth_token = AuthToken.find_by(token: params[:auth_token])

    raise AuthFailed if auth_token.blank?

    unless params[:controller].match(/\Acommon/)
      # 名前空間の判定
      name_space = {
        JvUser: 'jv/',
        DealerUser: 'dealer/',
        ContractorUser: 'contractor/',
        ProjectManagerUser: 'project_manager/'
      }[auth_token.tokenable_type.to_sym]

      # コントローラー名の先頭にユーザーの名前空間があるかを検証
      raise AuthFailed unless params[:controller].match(/\A#{name_space}/)
    end

    @login_user = auth_token.tokenable
  end

  # PDPA同意バージョンのチェック
  def check_pdpa_version
    # Contractor User のみをチェック
    return if login_user.class.to_s != "ContractorUser"

    unless login_user.agreed_latest_pdpa?
      render json: {
        success: false,
        error: "Require Agreement PDPA.",
        updated_pdpa_version: true,
      }
    end
  end

  # 規約バージョンのチェック
  def check_terms_of_service
    # Contractor User のみをチェック
    return if login_user.class.to_s != "ContractorUser"

    if login_user.not_agree_or_updated_terms_of_service?
      render json: {
        success: false,
        # 古いフロントバージョン用にコードは残す
        error: I18n.t("error_message.updated_terms_of_service"),
        # 古いフロントバージョン用に項目名は変えない
        updated_terms_of_service: true,
      }
    end
  end

  def check_temp_password
    # Contractor User のみをチェック
    return if login_user.class.to_s != "ContractorUser"

    if login_user.temp_password.present?
      render json: {
        success: false,
        error: "Require Change Password",
        require_change_password: true,
      }
    end
  end

  def rudy_error exception
    logger.info exception

    render json: {
      success: false,
      errors: [exception]
    }
  end

  # フロントのバージョン不一致エラー
  def unmatch_front_version(exception)
    logger.info exception.inspect
    render json: {
      success: false,
      error: I18n.t("error_message.updated_front_version"),
      updated_front_version: true,
    }
  end

  def unmatch_terms_of_service(exception)
    logger.info exception.inspect
    render json: {
      success: false,
      error: I18n.t("error_message.updated_terms_of_service"),
      updated_front_version: true,
    }
  end

  private
  attr_accessor :login_user

  def set_locale
    locale = params[:locale]&.to_sym
    locale_valid = [:en, :th].include?(locale)
    I18n.locale = locale_valid ? locale : I18n.default_locale
  end

  def check_front_version
    # テストは除外
    return nil if Rails.env.test?
    # RUDYからのリクエストは除外
    return nil if request.fullpath.include?('/api/rudy/')
    # Commonは除外
    return nil if request.fullpath.include?('/api/common/')
    # 開発時の画面以外からのリクエストは除外(Postmanなど)
    return nil if Rails.env.development? && request.origin.blank?
    # TODO いったんダウンロード系を除外
    return nil if request.fullpath.include?('/download_')

    db_front_version =
      if request.fullpath.include?('/api/jv/')
        SystemSetting.front_jv_version
      elsif request.fullpath.include?('/api/contractor/')
        SystemSetting.front_c_version
      elsif request.fullpath.include?('/api/dealer/')
        SystemSetting.front_d_version
      elsif request.fullpath.include?('/api/project_manager')
        SystemSetting.front_pm_version
      end

    if params[:front_version].blank? || params[:front_version].to_s != db_front_version
      raise UnmatchFrontVersion
    end
  end

  def mysql_error?(exception)
    exception.to_s.include?("Mysql2::Error")
  end

  # ネストしたリクエストパラメータがStringで渡されるために発生する#digメソッドエラーを防ぐ
  def parse_search_params
    search_params = params[:search]
    unless search_params.nil?
      params[:search] = JSON.parse(search_params) if search_params.is_a? String
    end
  end

  # Order Detailダイアログの共通のレスポンスフォーマット
  def format_jv_order_detail(order, target_ymd = nil)
    dealer     = order.dealer
    product    = order.product
    contractor = order.contractor
    site       = order.site
    # 変更申請をした商品
    applied_change_product = order.applied_change_product
    # リスケをした新しいオーダー
    rescheduled_new_order  = order.rescheduled_new_order
    # リスケしたFeeオーダー
    rescheduled_fee_order  = order.rescheduled_fee_order

    # Installments
    installments = order.installments.order(installment_number: :asc).map do |installment|
      {
        id:                 installment.id,
        installment_number: installment.installment_number,
        due_ymd:            installment.due_ymd,
        paid_up_ymd:        installment.paid_up_ymd,
        principal:          installment.principal.to_f,
        interest:           installment.interest.to_f,
        late_charge:        target_ymd ? installment.calc_late_charge(target_ymd) :
                                         installment.paid_late_charge.to_f,
        paid_principal:     installment.paid_principal.to_f,
        paid_interest:      installment.paid_interest.to_f,
        paid_late_charge:   installment.paid_late_charge.to_f,
        lock_version:       installment.lock_version
      }
    end

    {
      order_number:      order.order_number,
      installment_count: order.installment_count,
      purchase_ymd:      order.purchase_ymd,
      total_amount:      target_ymd ? order.calc_total_amount(target_ymd) :
                                      order.total_amount,
      total_paid_amount: order.paid_total_amount,
      paid_up_ymd:       order.paid_up_ymd,
      input_ymd:         order.input_ymd,
      is_user_can_cancel: can_open_cancenl_order_dialog(order),
      change_product_status: order.change_product_status_label,
      can_get_change_product_schedule: order.can_get_change_product_schedule?,
      product_changed_at:    order.product_changed_at,
      canceled_at:       order.canceled_at,
      canceled_user_id:  order.canceled_user_id,
      contractor: {
        tax_id:          contractor.tax_id,
        en_company_name: contractor.en_company_name,
        th_company_name: contractor.th_company_name,
        contractor_type: contractor.contractor_type_label[:label],
      },
      dealer:            {
        id:          dealer&.id,
        dealer_code: dealer&.dealer_code,
        dealer_name: dealer&.dealer_name,
        dealer_type: dealer&.dealer_type_label || Dealer.new.dealer_type_label,
      },
      installments: installments,
      product: {
        id:           product&.id,
        product_key:  product&.product_key,
        product_name: product&.product_name
      },
      applied_change_product: applied_change_product && {
        id:           applied_change_product.id,
        product_key:  applied_change_product.product_key,
        product_name: applied_change_product.product_name
      },
      site: site && {
        site_code: site.site_code,
        site_name: site.site_name,
        dealer: {
          id:          site.dealer.id,
          dealer_code: site.dealer.dealer_code,
          dealer_name: site.dealer.dealer_name,
          dealer_type: site.dealer.dealer_type_label,
        },
        site_credit_limit: site.site_credit_limit.to_f,
        available_balance: site.available_balance,
        closed:            site.closed?,
      },
      # オーダーがリスケされた新しいオーダーならtrueになる
      has_original_orders: order.has_original_orders?,
      # PFのオーダーか？
      belongs_to_project_finance: order.belongs_to_project_finance?,
      project: order.belongs_to_project_finance? && {
        project_code: order.project.project_code,
        project_name: order.project.project_name,
        start_ymd: order.project.start_ymd,
        finish_ymd: order.project.finish_ymd,
        status: order.project.status_label,
        phase: {
          id: order.project_phase.id,
          phase_number: order.project_phase.phase_number,
          status: order.project_phase.status_label,
          site: {
            site_code: order.project_phase_site.site_code,
            site_name: order.project_phase_site.site_name,
          }
        },
        project_manager: {
          project_manager_name: order.project.project_manager.project_manager_name,
        }
      },
      # オーダーをリスケした場合に以下の値が入る
      reschedule_information: rescheduled_new_order && {
        reschedule_order: {
          id:           rescheduled_new_order.id,
          order_number: rescheduled_new_order.order_number,
        },
        fee_order: rescheduled_fee_order && {
          id:           rescheduled_fee_order.id,
          order_number: rescheduled_fee_order.order_number,
        },
        rescheduled_user: rescheduled_new_order.rescheduled_user&.full_name,
        rescheduled_at:   rescheduled_new_order.rescheduled_at,
      },
      is_fee_order: order.fee_order,
      bill_date: order.bill_date,
      belongs_to_second_dealer: order.second_dealer.present?,
      purchase_amount_info: order.second_dealer && {
        first_dealer_info: {
          dealer: {
            dealer_name: order.dealer.dealer_name,
            dealer_type: order.dealer.dealer_type_label,
          },
          amount: order.first_dealer_amount.to_f,
        },
        second_dealer_info: {
          dealer: {
            dealer_name: order.second_dealer.dealer_name,
            dealer_type: order.second_dealer.dealer_type_label,
          },
          amount: order.second_dealer_amount.to_f,
        },
        amount: order.purchase_amount.to_f,
      }
    }
  end

  # C画面用
  def format_contractor_order_detail(order)
    dealer = order.dealer
    product = order.product
    contractor = order.contractor
    site = order.site
    # 変更申請をした商品
    applied_change_product = order.applied_change_product
    # リスケをした新しいオーダー
    rescheduled_new_order  = order.rescheduled_new_order
    # リスケしたFeeオーダー
    rescheduled_fee_order  = order.rescheduled_fee_order

    # Installments
    installments = order.installments.order(installment_number: :asc).map do |installment|
      {
        id:                 installment.id,
        installment_number: installment.installment_number,
        due_ymd:            installment.due_ymd,
        paid_up_ymd:        installment.paid_up_ymd,
        payment_amount:     installment.total_amount,
        lock_version:       installment.lock_version
      }
    end

    # Order
    {
      id:                    order.id,
      order_number:          order.order_number,
      installment_count:     order.installment_count,
      purchase_ymd:          order.purchase_ymd,
      total_amount:          order.total_amount,
      paid_total_amount:     order.paid_total_amount,
      paid_up_ymd:           order.paid_up_ymd,
      change_product_status: order.change_product_status_label,
      product_changed_at:    order.product_changed_at,
      dealer: {
        id:          dealer&.id,
        dealer_code: dealer&.dealer_code,
        dealer_name: dealer&.dealer_name,
        dealer_type: dealer&.dealer_type_label || Dealer.new.dealer_type_label,
      },
      installments: installments,
      product: {
        id:           product&.id,
        product_key:  product&.product_key,
        product_name: product&.product_name
      },
      applied_change_product: applied_change_product && {
        id:           applied_change_product.id,
        product_key:  applied_change_product.product_key,
        product_name: applied_change_product.product_name
      },
      site: site && {
        site_code: site.site_code,
        site_name: site.site_name,
        dealer: {
          id:          site.dealer.id,
          dealer_code: site.dealer.dealer_code,
          dealer_name: site.dealer.dealer_name,
          dealer_type: site.dealer.dealer_type_label,
        },
        site_credit_limit: site.site_credit_limit.to_f,
        available_balance: site.available_balance,
        closed:            site.closed?,
      },
      # オーダーがリスケされた新しいオーダーならtrueになる
      has_original_orders: order.has_original_orders?,
      # オーダーをリスケした場合に以下の値が入る
      reschedule_information: rescheduled_new_order && {
        new_order: {
          id:           rescheduled_new_order.id,
          order_number: rescheduled_new_order.order_number,
        },
        fee_order: rescheduled_fee_order && {
          id:           rescheduled_fee_order.id,
          order_number: rescheduled_fee_order.order_number,
        },
        rescheduled_user: rescheduled_new_order.rescheduled_user&.full_name,
        rescheduled_at:   rescheduled_new_order.rescheduled_at,
      },
      is_fee_order: order.fee_order,
    }
  end

  # オーダーキャンセルのダイアログを開ける判定(キャンセルできるとは異なる)
  def can_open_cancenl_order_dialog(order)
    # キャンセルされていない
    return false if order.canceled?

    # 管理者もしくはMDである
    return true if login_user.system_admin || login_user.md?

    # それ以外(staff)はInput Dateが未入力
    return order.input_ymd.blank?
  end
end
