class CreateProjectFinanceOrder
  def call(order)
    raise 'Too Little Amount' if order.purchase_amount.to_i < 1.0

    order.save!

    product = order.product

    # 約定日の算出
    due_ymd = product.calc_due_ymds(BusinessDay.today_ymd)[1]

    # 分割金額の取得
    installment_amounts = product.installment_amounts(order.purchase_amount, order.dealer&.interest_rate)
    # 支払い金額情報の取得
    installment_amount_data = installment_amounts[:installments][1]

    # Installmentの作成
    installment = Installment.new
    installment.contractor = order.contractor
    installment.order      = order
    installment.installment_number = 1 # 固定で1回
    installment.due_ymd    = due_ymd
    installment.principal  = installment_amount_data[:principal]
    installment.interest   = installment_amount_data[:interest]

    # Installment
    installment.save!

    return order
  end
end
