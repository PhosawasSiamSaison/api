class AutoRepaymentExceededAndCashback
  def call(contractor)
    # 環境変数で設定されている場合に実行する
    return unless JvService::Application.config.try(:auto_repayment_exceeded_and_cashback)

    # ExceededかCashbackがある場合のみ実行するが、CashbackがあってもPaymentの制約で使用できない場合があるので、消し込み処理内で再度判定している
    repayment_amount = (contractor.cashback_amount + contractor.exceeded_amount).round(2)

    if repayment_amount > 0
      comment = I18n.t('message.auto_repayment_exceeded_and_cashback_comment')
      payment_amount = 0 # ExceededとCashBackのみで支払うので入金額は 0にする
      payment_ymd = BusinessDay.today_ymd

      # 消し込み対象がなかった場合もerrorが返る
      # subtraction_repayment が自動消し込みの判定
      result = AppropriatePaymentToInstallments.new(
        contractor, payment_ymd, payment_amount, nil, comment, false, subtraction_repayment: true,
      ).call

      if result[:error].blank? && result[:paid_exceeded_and_cashback_amount].to_f > 0
        # メッセージとメールの送信
        SendReceivePaymentMessageAndEmail.new(contractor, payment_ymd, result[:paid_exceeded_and_cashback_amount]).call
      end
    end
  end
end
