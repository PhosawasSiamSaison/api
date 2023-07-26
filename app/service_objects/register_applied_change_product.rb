class RegisterAppliedChangeProduct
  include ErrorInfoModule

  def initialize(change_product_apply_id, orders, memo, login_user)
    @change_product_apply_id = change_product_apply_id
    @orders = orders
    @memo = memo
    @login_user = login_user
  end

  def call
    change_product_apply_id = @change_product_apply_id
    orders = @orders
    memo = @memo
    login_user = @login_user

    change_product_apply = ChangeProductApply.find(change_product_apply_id)

    # 承認と却下のオーダーを分ける
    approve_order_ids, reject_order_ids = split_order_ids(orders)

    applied_orders = change_product_apply.orders

    # 不正な操作のチェック
    raise 'オーダーの数が合わない' if orders.count != applied_orders.count

    # オーダーのインスタンスを取得
    approve_orders = applied_orders.find(approve_order_ids)
    reject_orders  = applied_orders.find(reject_order_ids)

    errors = []
    ActiveRecord::Base.transaction do
      approve_orders.each do |order|
        errors = approval(order, login_user)
        raise ActiveRecord::Rollback if errors.present?
      end

      reject_orders.each do |order|
        errors = reject(order, login_user)
        raise ActiveRecord::Rollback if errors.present?
      end

      change_product_apply.update!(
        memo: memo,
        register_user: login_user,
        completed_at: Time.zone.now,
      )
    end

    [errors, change_product_apply]
  end

  private
  def split_order_ids(orders)
    approve_order_ids = []
    reject_order_ids  = []

    orders.each do |order|
      status = order[:change_product_status]

      if status == 'approval'
        approve_order_ids.push(order[:id])
      elsif status == 'rejected'
        reject_order_ids.push(order[:id])
      else
        raise "不正なchange_product_status:  #{status}"
      end
    end

    [approve_order_ids, reject_order_ids]
  end

  def approval(order, login_user)
    # 状態チェック(承認ができなければ、データが古い)
    return [I18n.t("error_message.stale_object_error")] if !order.can_approval_change_product?

    # プロダクトの更新
    ChangeProduct.new(order, order.applied_change_product).call

    # オーダー（ローン変更情報）の更新
    set_order_change_product_values(order, login_user, :approval)

    return order.error_messages if !order.save

    # RUDYのAPIを呼ぶ(再約定したオーダーでは呼ばない)
    if !order.rescheduled_new_order?
      error = RudySwitchPayment.new(order).exec
    end

    [error] if error.present?
  end

  def reject(order, login_user)
    return [I18n.t("error_message.stale_object_error")] if !order.applied?

    # ローン変更情報の更新
    set_order_change_product_values(order, login_user, :rejected)

    order.error_messages unless order.save
  end

  def set_order_change_product_values(order, login_user, change_product_status)
    order.is_applying_change_product = false
    order.product_changed_at = Time.zone.now
    order.product_changed_user = login_user
    order.change_product_status = change_product_status
  end
end
