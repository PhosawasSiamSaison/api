# frozen_string_literal: true

class Jv::CommonController < ApplicationController
  before_action :auth_user

  def dealers
    render json: {
      success: true,
      dealers: format_dealers(Dealer.active)
    }
  end

  def areas
    render json: {
      success: true,
      areas:   format_areas(Area.all)
    }
  end

  def products
    products = Product.all.number_sort.map do |product|
      {
        id: product.id,
        product_key: product.product_key,
        product_name: product.product_name,
      }
    end

    render json: { success: true, products: products }
  end

  def header_info
    render json: {
      success:      true,
      login_user:   format_login_user(login_user),
      business_ymd: BusinessDay.business_ymd
    }
  end

  # 購入商品の詳細(CBM系)
  def item_list
    order = Order.find(params[:order_id])

    # RUDY から Items を取得
    rudy_items = RudySearchProduct.new(order).exec

    # Paging
    items, total_count = RudyApiBase.paging(rudy_items, params)

    render json: {
      success: true,
      order: {
        order_number: order.order_number,
        purchase_ymd: order.purchase_ymd,
        dealer:       {
          id:          order.dealer.id,
          dealer_code: order.dealer.dealer_code,
          dealer_name: order.dealer.dealer_name
        },
        items:        items,
        total_count:  total_count
      }
    }
  end

  # 購入商品の詳細(CPAC系と全てのProjectのオーダー)
  def detail_list
    order = Order.find(params[:order_id])
    site = order.any_site

    # RUDY から Items を取得
    rudy_items = RudySearchCpacProduct.new(order).exec

    # Paging
    items, total_count = RudyApiBase.paging(rudy_items, params)

    render json: {
      success: true,
      order: {
        order_number: order.order_number,
        purchase_ymd: order.purchase_ymd,
        dealer:       {
          id:          order.dealer.id,
          dealer_code: order.dealer.dealer_code,
          dealer_name: order.dealer.dealer_name
        },
        site: {
          site_name: site.site_name,
          site_code: site.site_code,
          closed:    site.closed?
        },
        items:        items,
        total_count:  total_count,
        belongs_to_project_finance: order.belongs_to_project_finance?,
      }
    }
  end

  def test
    contractor = Contractor.first

    SendMail.approve_contractor(contractor)

    render json: { success: true }
  end


  # ローン変更の情報を返す
  def change_product_schedule
    # 取得できるオーダーはorder.can_get_change_product_schedule?で許可されたorderのみにする
    order = Order.not_rescheduled_new_orders.find(params[:order_id])

    product = Product.find_by(product_key: params[:product_key])

    # 新しいスケジュールの算出
    new_installment = ChangeProductPaymentSchedule.new(order, product).call

    # switchを許可されたproductのみを取得する
    selectable_products = order.contractor.allowed_change_products(order.dealer.dealer_type)

    render json: {
      success: true,
      selectable_products: selectable_products.map{|product|
        {
          product_key: product.product_key,
          product_name: product.product_name,
        }
      },
      change_product_status: order.change_product_status_label,
      changed_product: format_changed_product(order),
      before: {
        count: 1, # 必ず1回払いの想定
        schedule: [
          due_ymd: order.change_product_first_due_ymd,
          amount: order.purchase_amount.to_f,
        ]
      },
      after: {
        count: new_installment[:count],
        schedule: new_installment[:schedules],
        total_amount: new_installment[:total_amount],
      },
      is_applying: order.is_applying_change_product,
      can_register: product.present? && order.can_register_change_product?(product),
      messages: order.change_product_errors,
      changed_at: order.product_changed_at,
      changed_user_name: order.product_changed_user&.full_name,
    }
  end

  # ローンの変更(申請されていない場合の登録)
  def register_change_product
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    order_id    = params.fetch(:order_id)
    product_key = params.fetch(:product_key)

    order = Order.can_change_product_orders.find(order_id)
    new_product = Product.find_by(product_key: product_key)

    # バリデーションチェック(排他制御)
    raise ActiveRecord::StaleObjectError if !order.can_register_change_product?(new_product)

    ActiveRecord::Base.transaction do
      # スケジュールなどを新しい商品へ更新
      ChangeProduct.new(order, new_product).call

      # オーダーのプロダクト変更情報の更新
      order.is_applying_change_product = false
      order.product_changed_at = Time.zone.now
      order.product_changed_user = login_user
      order.change_product_status = :registered

      # 業務エラーの発生はない
      order.save!

      # RUDYのAPIを呼ぶ(再約定したオーダーでは呼ばない)
      if !order.rescheduled_new_order?
        error = RudySwitchPayment.new(order).exec
      end

      # RUDY API エラーがあればシステムエラーを発生させる
      raise error.inspect if error.present?
    end

    render json: { success: true }
  end


  # Order Detailダイアログから起動するリスケ元のオーダーを表示するダイアログ(Original Order List)
  def rescheduled_order_list
    rescheduled_order = Order.rescheduled_new_orders.find(params.fetch(:order_id))

    new_order = {
      id: rescheduled_order.id,
      order_number: rescheduled_order.order_number,
      rescheduled_user: rescheduled_order.rescheduled_user&.full_name,
      rescheduled_at: rescheduled_order.rescheduled_at,
    }

    old_orders = rescheduled_order.rescheduled_old_orders.map do |order|
      {
        id: order.id,
        order_number: order.order_number,
        site_code: order.site&.site_code,
        dealer: {
          id:          order.dealer&.id,
          dealer_code: order.dealer&.dealer_code,
          dealer_name: order.dealer&.dealer_name,
          dealer_type: order.dealer&.dealer_type_label || Dealer.new.dealer_type_label,
        },
        purchase_ymd: order.purchase_ymd,
        input_ymd: order.input_ymd,
        purchase_amount: order.purchase_amount.to_f,
        paid_up_amount: order.paid_total_amount,
      }
    end

    render json: {
      success: true,
      order: new_order,
      rescheduled_old_orders: old_orders,
    }
  end

  # スコアリング画面とContractor詳細画面で表示されるダイアログ情報
  def credit_limit_information
    contractor = Contractor.find(params[:contractor_id])

    # 全てのDealerから買える場合は設定を表示しない
    dealer_types = contractor.use_only_credit_limit ? [] : ApplicationRecord.dealer_types.keys

    # 表示するDealer Type（全て）を返す
    dealer_type_limits = dealer_types.map do |dealer_type|
       # Dealerの一覧
      target_dealer_limits = contractor.latest_dealer_limits.includes(:dealer)
          .where(dealers: {dealer_type: dealer_type})

      {
        dealer_type: {
          code: dealer_type,
          label: I18n.t("enum.application_record.dealer_type.#{dealer_type}"),
        },
        is_enabled:        contractor.enabled_limit_dealer_types.include?(dealer_type.to_sym),
        limit_amount:      contractor.dealer_type_limit_amount(dealer_type),
        used_amount:       contractor.dealer_type_remaining_principal(dealer_type),
        available_balance: contractor.dealer_type_available_balance(dealer_type),
        dealers: target_dealer_limits.map do |dealer_limit|
          dealer = dealer_limit.dealer

          {
            id:                dealer.id,
            dealer_name:       dealer.dealer_name,
            limit_amount:      contractor.dealer_limit_amount(dealer),
            used_amount:       contractor.dealer_remaining_principal(dealer),
            available_balance: contractor.dealer_available_balance(dealer),
          }
        end
      }
    end

    render json: {
      success: true,
      eligibility: {
        limit_amount:       contractor.credit_limit_amount,
        used_amount:        contractor.remaining_principal,
        available_balance:  contractor.available_balance,
        class_type:         contractor.class_type_label,
        dealer_type_limits: dealer_type_limits,
      },
      is_user_can_update: login_user.md? 
    }
  end

  def update_credit_limit
    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    errors = CreateLimitAmounts.new.call(params, login_user)

    if errors.blank?
      render json: { success: true }
    else
      render json: { success: false, errors: errors }
    end
  end

  def credit_limit_history
    contractor = Contractor.find(params.fetch(:contractor_id))

    eligibilities = contractor.eligibilities.order(created_at: :desc).map do |eligibility|
      formatted_dealer_type_limits = eligibility.dealer_type_limits.map {|dealer_type_limit|
        dealer_limits = DealerLimit.includes(:dealer)
          .where(eligibility: eligibility, dealers: {dealer_type: dealer_type_limit.dealer_type})

        formatted_dealers = dealer_limits.map {|dealer_limit|
          {
            dealer_name:  dealer_limit.dealer.dealer_name,
            limit_amount: dealer_limit.limit_amount.to_f,
          }
        }

        {
          dealer_type:  dealer_type_limit.dealer_type_label,
          limit_amount: dealer_type_limit.limit_amount.to_f,
          dealers:      formatted_dealers
        }
      }

      {
        comment:            eligibility.comment,
        updated_at:         eligibility.created_at, # updated_atは更新されるのでcreated_atを返す
        update_user_name:   eligibility.create_user&.full_name,
        limit_amount:       eligibility.limit_amount.to_f,
        class_type:         eligibility.class_type_label,
        dealer_type_limits: formatted_dealer_type_limits,
      }
    end

    render json: {
      success: true,
      eligibilities: eligibilities,
    }
  end


  private
  def format_login_user (login_user)
    {
      id:        login_user.id,
      user_name: login_user.user_name,
      full_name: login_user.full_name,
      user_type: login_user.user_type_label,
      is_system_admin: login_user.system_admin?
    }
  end

  def format_dealers (dealers)
    return dealers.map do |dealer|
      {
        id:          dealer.id,
        dealer_code: dealer.dealer_code,
        dealer_name: dealer.dealer_name,
      }
    end
  end

  def format_areas(areas)
    areas.map do |area|
      {
        id:        area.id,
        area_name: area.area_name
      }
    end
  end

  def format_changed_product(order)
    return nil if order.product_changed_at.blank? || order.rejected?

    {
      product_key: order.product.product_key,
      product_name: order.product.product_name
    }
  end
end
