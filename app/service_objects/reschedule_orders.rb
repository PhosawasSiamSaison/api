class RescheduleOrders
  def call(contractor_id, late_charge_ymd, order_ids, reschedule_order_count,
    fee_order_count, no_interest, set_credit_limit_to_zero, rescheduled_user)

    contractor = Contractor.find(contractor_id)

    reschedule_product = Product.reschedule_product(reschedule_order_count, no_interest)
    fee_product = Product.fee_product(fee_order_count)

    # 対象外のオーダーは除外する
    old_orders = target_orders(contractor).find(order_ids)
    old_orders = Order.where(id: old_orders.map(&:id))

    # 排他制御
    if !old_orders.all?(&:can_reschedule?)
      raise ActiveRecord::StaleObjectError
    end

    # 指定したオーダーの残り元本の支払い残金
    principal_purchase = old_orders.remaining_principal

    # Feeの購入金額
    fee_purchase = old_orders.calc_remaining_interest_and_late_charge(late_charge_ymd)

    if reschedule_order_count < 1 || 60 < reschedule_order_count
      return [I18n.t('error_message.invalid_reschedule_order_count')]
    end

    if fee_order_count < 0 || 60 < fee_order_count || (fee_purchase > 0 && fee_order_count == 0)
      return [I18n.t('error_message.invalid_fee_order_count')]
    end

    today_ymd = BusinessDay.today_ymd
    
    # Order Numberを作成する
    new_order_number, fee_order_number = Order.generate_reschedule_order_number()

    ActiveRecord::Base.transaction do
      # 先にFee Orderを作成する
      if fee_purchase > 0
        temp_fee_order = Order.new(
          contractor:         contractor,
          order_number:       fee_order_number,
          reschedule_product: fee_product,
          installment_count:  fee_product.number_of_installments,
          purchase_ymd:       today_ymd,
          purchase_amount:    fee_purchase,
          input_ymd:          today_ymd,
          input_ymd_updated_at: Time.now,
          rescheduled_at:       Time.now,
          rescheduled_user:   rescheduled_user,
          fee_order:          true
        )

        fee_order = CreateOrder.new.call(temp_fee_order)
      end

      # 元本を元にしたオーダーを作成
      temp_new_order = Order.new(
        contractor:         contractor,
        order_number:       new_order_number,
        reschedule_product: reschedule_product, # attr_accessor. CreateOrderで使用
        installment_count:  reschedule_product.number_of_installments,
        purchase_ymd:       today_ymd,
        purchase_amount:    principal_purchase,
        input_ymd:          today_ymd,
        input_ymd_updated_at: Time.now,
        rescheduled_at:       Time.now,
        rescheduled_user:   rescheduled_user,
        fee_order:          false
      )

      new_order = CreateOrder.new.call(temp_new_order)

      # 指定したオーダーはリスケ済み扱いへ
      old_orders.each do |order|
        order.reload

        order.update!(
          rescheduled_new_order: new_order,
          rescheduled_fee_order: fee_order
        )

        order.installments.each do |installment|
          installment.update!(rescheduled: true)
          installment.remove_from_payment
        end
      end

      if set_credit_limit_to_zero
        # 現在のCredit Class Type を取得
        current_class_type = contractor.eligibilities.latest.class_type

        # チェックありはCredit Limit Amountを0にする
        params = {
          contractor_id: contractor.id,
          eligibility: {
            limit_amount: 0,
            class_type: current_class_type,
            comment: 'Reschedule',
            dealer_types: []
          }
        }

        errors = CreateLimitAmounts.new.call(params, rescheduled_user)

        raise ActiveRecord::Rollback if errors.present?
      end
    end

    # 自動消し込み(メール送信があるのでトランザクションの外で処理をする)
    AutoRepaymentExceededAndCashback.new.call(contractor)

    return nil
  end

  private
  def target_orders(contractor)
    contractor.orders.inputed_ymd.payable_orders
  end
end
