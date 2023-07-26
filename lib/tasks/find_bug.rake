desc 'バグを探す'
task find_bug: :environment do
  find_interest_bug()
  find_cashback_bug()
end

private
def find_interest_bug
  p '--- 利息の検証 ---'

  count = 0
  orders = Order.all

  orders.each do |order|
    product = order.product
    amount = order.purchase_amount
    dealer = order.dealer

    installment_amounts = product.installment_amounts(amount.to_f, dealer.interest_rate)
    new_installments = installment_amounts[:installments]

    order.installments.order(:installment_number).each do |installment|
      installment_number = installment.installment_number

      new_installment = new_installments[installment_number]

      new_principal = new_installment[:principal].to_f
      new_interest = new_installment[:interest].to_f

      principal = installment.principal.to_f
      interest = installment.interest.to_f

      if new_interest != interest
        count += 1
        p "installment_id: #{installment.id}. 誤: #{interest}, 正: #{new_interest}"
      end
    end
  end

  p "不具合データ: #{count}件"
end

def find_cashback_bug
  p '--- キャッシュバックの検証 ---'

  count = 0
  cashback_histories = CashbackHistory.gain

  cashback_histories.each do |cashback_history|
    order = cashback_history.order

    new_amount = order.calc_cashback_amount.to_f
    amount = cashback_history.cashback_amount.to_f

    if new_amount != amount
      p "order_id: #{order.id}, 誤: #{amount}, 正: #{new_amount}"
      count += 1
    end
  end

  p "不具合データ: #{count}件"
end
