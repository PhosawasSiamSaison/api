class RescheduleNewSchedule
  def call(amount, product)
    # 返却用の変数
    initial_value = {
      count: 0,
      schedule: [],
      total_amount: 0.0
    }

    # 画面表示時は商品が未選択なので空で返す
    if product.blank?
      return initial_value
    end

    # 約定日の算出
    due_ymds = product.calc_due_ymds(BusinessDay.today_ymd)

    # 分割金額の算出
    installment_amounts = product.installment_amounts(amount, nil)

    schedules = []
    # データの整形
    product.number_of_installments.times.each.with_index(1) do |_, i|
      data = {}
      data[:installment_number] = i
      data[:due_ymd] = due_ymds[i]
      data[:principal] = installment_amounts[:installments][i][:principal]
      data[:interest] = installment_amounts[:installments][i][:interest]
      data[:amount] = installment_amounts[:installments][i][:total]

      schedules.push(data)
    end

    initial_value[:count]        = schedules.count
    initial_value[:schedule]     = schedules
    initial_value[:total_principal] = schedules.sum{|item| item[:principal]}.round(2).to_f
    initial_value[:total_interest] = schedules.sum{|item| item[:interest]}.round(2).to_f
    initial_value[:total_amount] = schedules.sum{|item| item[:amount]}.round(2).to_f

    initial_value
  end
end
