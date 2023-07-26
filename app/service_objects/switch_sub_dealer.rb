# frozen_string_literal: true

class SwitchSubDealer
  def get_information
    prev_due_ymd = BusinessDay.prev_due_ymd()
    next_due_ymd = BusinessDay.one_month_after_closing_ymd(BusinessDay.to_date(prev_due_ymd))

    orders = []

    PaymentDefault.where(due_ymd: BusinessDay.prev_due_ymd(), status: :over_due).each do |payment|
      payment.installments.each do |installment|
        next unless switch_target?(installment)

        order = installment.order
        dealer = order.dealer
        contractor = order.contractor

        orders.push({
          id: order.id,
          order_number: order.order_number,
          dealer: {
            id:          dealer.id,
            dealer_code: dealer.dealer_code,
            dealer_name: dealer.dealer_name,
            dealer_type: dealer.dealer_type_label,
          },
          en_company_name: contractor.en_company_name,
          th_company_name: contractor.th_company_name,
          amount: order.purchase_amount.to_f,
          lock_version: order.lock_version,
        })
      end
    end

    {
      prev_due_ymd: prev_due_ymd,
      next_due_ymd: next_due_ymd,
      orders: orders
    }
  end

  def exec_switch(orders, login_user)
    # システムエラー発生時は全てをロールバックする
    ActiveRecord::Base.transaction do
      order_ids = orders.map{|order| order['id']}

      Order.find(order_ids).each do |order|
        installment = order.installments.first

        # パラメーターのlock_versionを取得
        params_lock_version = orders.find{|_order| _order['id'] == order.id}['lock_version']

        # 排他制御
        raise ActiveRecord::StaleObjectError if order.lock_version != params_lock_version
        raise  ActiveRecord::StaleObjectError unless switch_target?(installment)

        product5 = Product.find_by(product_key: 5)

        # スケジュールなどを新しい商品へ更新
        ChangeProduct.new(order, product5).call

        # 申請中のレコードを取得
        change_product_apply = order.change_product_apply

        # オーダーのプロダクト変更情報の更新
        order.product_changed_at = Time.zone.now
        order.product_changed_user = login_user
        order.change_product_status = :registered

        # 申請中の情報を消す
        # (申請でも取り消してから登録の判定にする。複数申請だと１つのみを承認する処理は複雑になるため)
        order.is_applying_change_product = false
        order.applied_change_product = nil
        order.change_product_applied_at = nil
        order.change_product_applied_user = nil
        order.change_product_apply = nil

        order.save!

        # change_product_apply のorderがなくなった場合は削除する
        if change_product_apply && change_product_apply.orders.blank?
          change_product_apply.delete
        end

        begin
          # RUDYのAPIを呼び出す
          RudySwitchPayment.new(order).exec
        rescue Exception => e
          Rails.logger.info e.inspect
        end
      end
    end
  end

  private
  # Switch可能の判定
  def switch_target?(installment)
    order = installment.order

    # Switch対象外を除外
    return false if installment.installment_number != 1

    # 支払いがされていないこと
    return false if installment.paid_total_amount > 0

    # SubDealerであること
    contractor = installment.order.contractor
    return false if !contractor.sub_dealer?

    # リスケされた古いオーダーでないこと
    return false if order.rescheduled?

    # リスケされた新しいオーダーでないこと
    return false if order.rescheduled_new_order?

    # 今の商品キーが1であること
    return false if order.product.product_key != 1

    # 権限設定で許可されていること
    dealer = order.dealer
    product5 = Product.find_by(product_key: 5)
    return false if !contractor.available_switch?(dealer, product5)

    # SwitchがRejectされていないこと
    return false if order.rejected?

    # Switch申請中の場合は商品５であること
    return false if order.is_applying_change_product && order.applied_change_product != product5

    # キャンセルされていないこと
    return false if order.canceled?

    true
  end
end