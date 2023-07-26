class ChangeProductPaymentSchedule
  def initialize(order, new_product)
    @order = order
    @new_product = new_product
  end

  def call
    order = @order
    new_product = @new_product

    # 返却用の変数
    initial_value = {
      count: 0,
      schedules: [],
      total_amount: 0.0
    }

    # 画面表示時は商品が未選択なので空で返す
    if new_product.blank?
      return initial_value
    end

    # 約定日の算出
    due_ymds = new_product.calc_due_ymds(order.input_ymd || BusinessDay.today_ymd)

    # 分割金額の算出
    installment_amounts =
      new_product.installment_amounts(order.purchase_amount, order.dealer.interest_rate)

    schedules = []
    # データの整形
    new_product.number_of_installments.times.each.with_index(1) do |_, i|
      data = {}
      data[:due_ymd] = due_ymds[i]
      data[:amount] = installment_amounts[:installments][i][:total]

      schedules.push(data)
    end

    initial_value[:count]        = schedules.count
    initial_value[:schedules]    = schedules
    initial_value[:total_amount] = schedules.sum{|item| item[:amount]}.round(2).to_f

    initial_value
  end

  private
end
