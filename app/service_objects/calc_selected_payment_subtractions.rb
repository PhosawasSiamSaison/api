class CalcSelectedPaymentSubtractions
  include CalcAmountModule

  def initialize(contractor, target_ymd = BusinessDay.today_ymd, is_exemption_late_charge = false, installment_ids: [])
    @contractor = contractor
    @target_ymd = target_ymd
    @is_exemption_late_charge = is_exemption_late_charge
    @installment_ids = installment_ids
  end

  def call
    contractor = @contractor
    payments = contractor.payments
    installment_ids = @installment_ids
    target_ymd = @target_ymd

    # 返却用変数
    calced_subtractions = {}

    # สำหรับการคำนวณเงินคืนและส่วนเกิน
    can_use_total_exceeded = contractor.exceeded_amount
    can_use_total_cashback = contractor.cashback_amount

    payments.each do |payment|
      installments = payment.installments.payable_installments.appropriation_sort.where(id: installment_ids)

      next unless installments.present?
      # 支払い済みのpaymentは
      if payment.paid?
        calced_subtractions[payment.id] = {
          exceeded: 0.0,
          cashback: 0.0,
          total: 0.0,
          paid_exceeded: payment.paid_exceeded.to_f,
          paid_cashback: payment.paid_cashback.to_f,
          paid_total: (payment.paid_exceeded + payment.paid_cashback).round(2).to_f
        }

        next
      end

      # ไม่รวมเงินคืนที่ได้รับจากการชำระเงินปัจจุบัน เนื่องจากไม่สามารถใช้กับการชำระเงินเดิมได้
      exclusion_cashback_amount = payment.cashback_histories.gain_total
      can_use_total_cashback = (can_use_total_cashback - exclusion_cashback_amount).round(2)

      can_use_exceeded = 0.0
      can_use_cashback = 0.0

      # 残りの支払額(exceeded, cashbackの算出用)
      remaining_balance_exclude_late_charge = installments.inject(0) {|sum, installment|
        sum + installment.remaining_balance_exclude_late_charge
      }.round(2).to_f
      remaining_balance = installments.inject(0) {|sum, installment|
        sum + installment.remaining_balance(target_ymd)
      }.round(2).to_f
      remaining_balance = @is_exemption_late_charge ? remaining_balance_exclude_late_charge : remaining_balance

      # 使用できるexceededを算出する
      if can_use_total_exceeded > 0
        can_use_exceeded = [can_use_total_exceeded, remaining_balance].min
        # 全体から減算
        can_use_total_exceeded = (can_use_total_exceeded - can_use_exceeded).round(2)
        remaining_balance = (remaining_balance - can_use_exceeded).round(2)
      end

      # exceededがなくなったらcashbackを使用する
      if can_use_total_exceeded == 0 && can_use_total_cashback > 0
        # 使用できるcashback
        can_use_cashback = [can_use_total_cashback, remaining_balance].min
        # 全体から減算
        can_use_total_cashback = (can_use_total_cashback - can_use_cashback).round(2)
      end

      calced_subtractions[payment.id] = {
        exceeded: can_use_exceeded,
        cashback: can_use_cashback,
        total: (can_use_exceeded + can_use_cashback).round(2),
        paid_exceeded: payment.paid_exceeded.to_f,
        paid_cashback: payment.paid_cashback.to_f,
        paid_total: (payment.paid_exceeded + payment.paid_cashback).round(2).to_f
      }

      # 除外したキャッシュバックをトータルへ戻す（次のpaymentでは使用できるようにする）
      can_use_total_cashback = (can_use_total_cashback + exclusion_cashback_amount).round(2)
    end

    calced_subtractions
  end
end
