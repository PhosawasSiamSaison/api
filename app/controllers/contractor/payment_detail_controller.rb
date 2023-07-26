# frozen_string_literal: true

class Contractor::PaymentDetailController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def payment_detail
    contractor = login_user.contractor
    payment = contractor.payments.find(params[:payment_id])

    render json: {
      success: true,
      checking_payment: contractor.check_payment,
      # Switchボタン・アイコンの表示判定に使用
      allowed_change_products: payment.contractor.allowed_change_products.map{|product|
        {
          product_key: product.product_key,
          product_name: product.product_name,
        }
      },
      payments: format_payment(contractor, payment)
    }
  end

  # ローン変更ダイアログの内容を取得
  def change_product_schedule
    # TODO 指定商品が変更できる商品かの判定を入れる。(Stale Object)

    contractor = login_user.contractor
    payment = contractor.payments.find(params[:payment_id])
    new_product = Product.find_by(product_key: params[:product_key])

    # 一括ローン変更申請画面に表示するオーダーを取得
    target_orders = payment.can_apply_change_product_orders

    render json: {
      success: true,
      orders: target_orders.map {|order|
        # 新しいスケジュールの算出
        new_installment = ChangeProductPaymentSchedule.new(order, new_product).call

        # オーダー毎の選択可能な商品
        selectable_products =
          contractor.allowed_change_products(order.dealer.dealer_type).map{|product|
            {
              product_key: product.product_key,
              product_name: product.product_name,
            }
          }

        {
          id: order.id,
          order_number: order.order_number,
          dealer_type: order.dealer.dealer_type_label,
          has_original_orders: order.has_original_orders?,
          change_product_status: order.change_product_status_label,
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
          # TODO 申請できるオーダーのみ表示になったので一旦コメントアウト。確定したら消す
          can_apply: order.can_apply_change_product?,
          messages: order.apply_change_product_errors,
          selectable_products: selectable_products,
        }
      },
      can_apply: new_product.present? && payment.has_can_apply_change_product_order?,
    }
  end

  # ローン一括変更の申請
  def apply_change_product
    # 申請するオーダーと自動承認するオーダーを分ける
    apply_switch_orders, auto_approval_switch_orders = split_orders(params[:orders])

    # 申請するオーダー
    apply_switch_order_ids = []
    apply_switch_product_keys = []
     # 引数をそれぞれの配列にセットする
    apply_switch_orders.each do |order|
      apply_switch_order_ids.push(order[:id])
      apply_switch_product_keys.push(order[:product_key])
    end

    # 自動承認するオーダー
    auto_approval_switch_order_ids = []
    auto_approval_switch_product_keys = []
     # 引数をそれぞれの配列にセットする
    auto_approval_switch_orders.each do |order|
      auto_approval_switch_order_ids.push(order[:id])
      auto_approval_switch_product_keys.push(order[:product_key])
    end

    errors = []
    change_product_apply = nil

    ActiveRecord::Base.transaction do
      # 申請のみのオーダー
      if apply_switch_orders.present?
        success, errors, _ = ApplyChangeProduct.new(
          apply_switch_order_ids, apply_switch_product_keys, login_user
        ).call

        raise ActiveRecord::Rollback if !success
      end

      # 自動承認するオーダー
      if auto_approval_switch_orders.present?
        success, errors, change_product_apply = AutoApprovalChangeProduct.new(
          auto_approval_switch_order_ids, auto_approval_switch_product_keys, login_user
        ).call

        raise ActiveRecord::Rollback if !success
      end
    end

    # 自動承認した場合はSMSを送る
    if errors.blank? && auto_approval_switch_orders.present?
      SendApprovalChangeProductSms.new(change_product_apply).call
    end

    if errors.blank?
      render json: { success: true }
    else
      render json: { success: false, errors: errors }
    end
  end

  private
  def format_payment(contractor, payment)
    # CashbackとExceededを計算してpaymentを取得
    calced_payment = CalcPaymentDetail.new(payment).call

    # orderのinput_ymdがないinstallmentは除外する
    installments = payment.installments.includes(:order)
      .inputed_date_installments.appropriation_sort

    # Payment
    {
      due_ymd: payment.due_ymd,
      paid_up_ymd: payment.paid_up_ymd,
      total_amount: calced_payment[:remaining_amount],
      status: payment.status,

      due_amount: calced_payment[:due_amount],
      cashback: calced_payment[:total_cashback],
      exceeded: calced_payment[:total_exceeded],
      paid_total_amount: calced_payment[:paid_total_amount],
      remaining_amount: calced_payment[:remaining_amount],

      installments: installments.map { |installment|
        order = installment.order

        {
          id: installment.id,
          status: format_status(installment),
          can_apply_change_product: order.can_apply_change_product?,
          can_change_product: order.can_change_product?,
          is_product_changed: order.product_changed?,
          order: {
            id: order.id,
            order_number: order.order_number,
            installment_count: order.installment_count,
          },
          dealer: {
            id:          order.dealer&.id,
            dealer_code: order.dealer&.dealer_code,
            dealer_name: order.dealer&.dealer_name,
          },
          installment_number: installment.installment_number,
          paid_up_ymd: installment.paid_up_ymd,
          total_amount: installment.total_amount,
          lock_version: installment.lock_version,
        }
      }
    }
  end

  # アイコン表示用のステータス
  def format_status(installment)
    if installment.paid?
      'paid'
    elsif installment.over_due?
      'over_due'
    else
      nil
    end
  end

  def split_orders(orders_params)
    apply_switch_orders = []
    auto_approval_switch_orders = []

    # 申請と自動承認をdealer_typeで分ける
    orders_params.each do |order_params|
      order = Order.find(order_params[:id])

      if order.dealer.dealer_type_setting.switch_auto_approval
        auto_approval_switch_orders.push(order_params)
      else
        apply_switch_orders.push(order_params)
      end
    end

    [apply_switch_orders, auto_approval_switch_orders]
  end
end