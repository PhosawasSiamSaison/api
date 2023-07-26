class CreateOrder
  def call(order)
    raise 'Too Little Amount' if order.purchase_amount.to_i < 1.0

    ActiveRecord::Base.transaction do
      order.save!

      product = order.rescheduled_new_order? ? order.reschedule_product : order.product

      # 約定日の算出
      due_ymds = product.calc_due_ymds(BusinessDay.today_ymd)

      # 分割金額の取得
      installment_amounts = product.installment_amounts(order.purchase_amount, order.dealer&.interest_rate)

      # Installmentsの作成
      order.installment_count.times.each.with_index(1) do |_, i|
        # 約定日の取得
        due_ymd = due_ymds[i]

        # 支払い金額情報の取得
        installment_amount_data = installment_amounts[:installments][i]

        # Paymentの作成、または更新
        payment = Payment.find_or_initialize_by(
          contractor: order.contractor,
          due_ymd: due_ymd,
        )

        # 支払い金額を追加
        payment.total_amount += installment_amount_data[:total]

        # Cpacは購入時にinput_dateが入るので、paidのステータスを戻す場合このタイミングで戻す
        payment.rollback_paid_status if order.input_ymd.present? && payment.paid?

        payment.save!

        # Installmentの作成
        installment = Installment.new
        installment.contractor = order.contractor
        installment.order      = order
        installment.payment    = payment
        installment.installment_number = i
        installment.due_ymd    = due_ymd
        installment.principal  = installment_amount_data[:principal]
        installment.interest   = installment_amount_data[:interest]
        # FeeOrderの場合は遅損金が発生しないフラグを立てる
        installment.exempt_late_charge = order.fee_order

        # Installment
        installment.save!
      end
    end

    return order
  end
end
