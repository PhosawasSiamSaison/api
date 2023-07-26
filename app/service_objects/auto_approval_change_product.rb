class AutoApprovalChangeProduct
  def initialize(order_ids, product_keys, contractor_user)
    @order_ids = order_ids
    @product_keys = product_keys
    @contractor_user = contractor_user
  end

  def call
    success = nil
    errors = []
    change_product_apply = nil

    ActiveRecord::Base.transaction do
      # 申請
      success, errors, change_product_apply =
        ApplyChangeProduct.new(order_ids, product_keys, contractor_user).call

      return [success, errors] if !success

      # 承認
      errors, _ = RegisterAppliedChangeProduct.new(
        change_product_apply.id,
        format_orders(change_product_apply.orders),
        "Auto Approval",
        nil
      ).call
    end

    [errors.blank?, errors, change_product_apply]
  end

  private
  attr_reader :order_ids, :product_keys, :contractor_user

  # 全て承認のオーダー形式に整形する
  def format_orders(orders)
    orders.map do |order|
      {
        id: order.id,
        change_product_status: "approval"
      }
    end
  end
end
