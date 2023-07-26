module CalcAmountModule
  # 指定の金額から減算をした残りの金額を返す
  def calc_subtraction(target_amount, subtraction_amount)
    #  900 = 1000 -  100
    # -800 =  200 - 1000
    calced_amount = (target_amount - subtraction_amount).round(2)

    target_amount       = [calced_amount, 0].max.to_f
    subtraction_amount  = [calced_amount, 0].min.abs.to_f

    [target_amount, subtraction_amount]
  end
end