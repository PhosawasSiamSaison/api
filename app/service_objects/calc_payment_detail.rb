class CalcPaymentDetail
  include CalcAmountModule

  def initialize(payment)
    @payment = payment
  end

  def call
    payment = @payment
    contractor = payment.contractor

    # cashbackとexceededにpaid_exceededとpaid_cashbackを加算
    # paid_total_amountからpaid_exceededとpaid_cashbackを減算

    # 利用可能な exceeded, cashback の算出
    calc_payment_subtractions = CalcPaymentSubtractions.new(contractor).call
    can_use_exceeded = calc_payment_subtractions[payment.id][:exceeded]
    can_use_cashback = calc_payment_subtractions[payment.id][:cashback]
    # 利用可能な exceeded, cashback の合計
    can_use_subtract = (can_use_exceeded + can_use_cashback).round(2).to_f


    # [Due Amount] 支払い合計金額
    due_amount = payment.due_amount

    # [Exceeded] exceeded の合計
    total_exceeded = (can_use_exceeded + payment.paid_exceeded).round(2).to_f

    # [Cashback] cashback の合計
    total_cashback = (can_use_cashback + payment.paid_cashback).round(2).to_f

    # [Paid Amount] exceeded, cashback を除いた支払い済み金額
    paid_total_amount = (payment.paid_total_amount - (payment.paid_exceeded + payment.paid_cashback)).round(2).to_f

    # [Remaining Amount] exceeded, cashback を加味した残りの支払い金額
    remaining_amount = (payment.remaining_balance - can_use_subtract).round(2).to_f

    {
      due_amount: due_amount,
      total_cashback: total_cashback,
      total_exceeded: total_exceeded,
      paid_total_amount: paid_total_amount,
      remaining_amount: remaining_amount,
    }
  end
end
