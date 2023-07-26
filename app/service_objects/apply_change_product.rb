class ApplyChangeProduct
  def initialize(order_ids, product_keys, contractor_user)
    @order_ids = order_ids
    @product_keys = product_keys
    @contractor_user = contractor_user
  end

  def call
    orders = contractor_user.contractor.orders.find(order_ids)
    contractor = contractor_user.contractor

    # オーダーが未選択ならエラー
    return [false, [I18n.t("error_message.stale_object_error")]] if order_ids.blank?

    # 商品が変更許可されていない場合
    orders.each_with_index do |order, idx|
      product = Product.find_by(product_key: product_keys[idx])

      if !contractor.available_switch?(order.dealer, product)
        return [false, [I18n.t("error_message.stale_object_error")]]
      end
    end

    errors = []
    change_product_apply = nil

    ActiveRecord::Base.transaction do
      # ローン変更申請レコードの作成
      change_product_apply = ChangeProductApply.create!(
        contractor: contractor_user.contractor,
        apply_user: contractor_user,
        due_ymd: orders.first.payments.first.due_ymd,
      )

      # オーダーの更新
      orders.each_with_index do |order, idx|
        errors = check_validation(order)

        raise ActiveRecord::Rollback if errors.present?

        product = Product.find_by(product_key: product_keys[idx])

        order.update!(
          change_product_status: :applied,
          is_applying_change_product: true,
          applied_change_product: product,
          change_product_applied_at: Time.zone.now,
          change_product_applied_user: contractor_user,
          change_product_apply: change_product_apply,
        )
      end
    end

    [errors.blank?, errors, change_product_apply]
  end

  private
  attr_reader :order_ids, :product_keys, :contractor_user

  def check_validation(order)
    # 申請可能期日を過ぎている
    if order.over_apply_change_product_limit_date?
      return [I18n.t("error_message.over_apply_change_product_limit_date")]
    end

    # 排他チェック(登録時に申請ができなければ、データが古い)
    if !order.can_apply_change_product?
      return [I18n.t("error_message.stale_object_error")]
    end
  end
end
