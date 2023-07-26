# 一部入金済みをExceededへ移す処理
class AdjustPaidOfInstallment
  include ErrorInfoModule

  def call(installment, login_user)
    # 排他チェック
    raise ActiveRecord::StaleObjectError unless installment.can_adjust_repayment(login_user)

    # 既存データ(対応前に作成されたInstallment)は対象外(マイグレーションでNULLに更新済み)
    if installment.used_exceeded.nil? || installment.used_cashback.nil?
      return set_errors('error_message.not_applicable_for_adjust_repayment')
    end

    # 項目がNULLの場合は処理しない(対応前のSiteLimitが下げられたinstallmentは対象外へ更新済み)
    if installment.reduced_site_limit.nil?
      return set_errors('error_message.not_applicable_for_adjust_repayment')
    end

    ActiveRecord::Base.transaction do
      # 履歴の作成(データ更新前に保持する)
      adjust_repayment_history = AdjustRepaymentHistory.new(
        created_user: login_user,
        installment: installment
      )
      adjust_repayment_history.insert_association
      adjust_repayment_history.save!

      # Site Limitを戻す
      if installment.order.site_order? && installment.reduced_site_limit > 0
        site = installment.order.site
        site.site_credit_limit += installment.reduced_site_limit
        site.save!

        # RUDYへ減額値を通知
        RudyUpdateSiteLimit.new(installment.order).exec
      end

      # paymentの更新
      payment = installment.payment
      payment.paid_exceeded -= installment.used_exceeded
      payment.paid_cashback -= installment.used_cashback
      payment.paid_total_amount -= installment.paid_total_amount
      payment.save!

      # 免除の削除
      installment.exemption_late_charges.delete_all

      # installment_historyの削除
      installment.installment_histories.except_first_record.delete_all

      # installment_historyの最初のレコードの更新
      installment.installment_histories.first_record.update!(to_ymd: '99991231')

      # Exceededへの追加
      contractor = installment.contractor
      contractor.pool_amount += installment.paid_total_amount
      contractor.save!

      # installmentの更新
      installment.paid_principal = 0
      installment.paid_interest = 0
      installment.paid_late_charge = 0
      installment.used_exceeded = 0
      installment.used_cashback = 0
      installment.reduced_site_limit = 0
      installment.save!
    end

    # エラーなし
    return []
  end
end
