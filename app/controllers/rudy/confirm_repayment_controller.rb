# frozen_string_literal: true

class Rudy::ConfirmRepaymentController < Rudy::ApplicationController
  DUPLICATE_REPAYMENT_ID = 'duplicate_repayment_id'

  def call
    tax_id         = params.fetch(:tax_id)
    payment_ymd    = params.fetch(:received_date)
    payment_amount = params.fetch(:received_amount).to_f
    repayment_id   = params.fetch(:repayment_id)

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    # 使用可能設定のチェック(System)
    unless JvService::Application.config.try(:enable_rudy_confirm_payment)
      raise(ValidationError, 'disabled_setting')
    end

    # 使用可能設定のチェック(Contractor)
    unless contractor.enable_rudy_confirm_payment
      raise(ValidationError, 'disabled_contractor_setting')
    end

    # 自動入金の重複チェック
    raise(ValidationError, DUPLICATE_REPAYMENT_ID) if ReceiveAmountHistory.exists?(repayment_id: repayment_id)

    # 必須チェック
    raise(ValidationError, 'invalid_repayment_id') if repayment_id.blank?

    # 金額チェック
    raise(ValidationError, 'invalid_amount') if payment_amount <= 0 # 0も許可しない

    # 日付のフォーマットチェック
    begin
      raise if payment_ymd.length != 8
      Date.parse(payment_ymd)
    rescue => e
      raise(ValidationError, 'invalid_date')
    end

    begin
      # 入金の実行
      result = AppropriatePaymentToInstallments.new(
        contractor,
        payment_ymd,
        payment_amount,
        nil, # create_user
        'Auto-repayment', # comment
        repayment_id: repayment_id
      ).call
      error = result[:error]
    rescue ActiveRecord::RecordNotUnique => e
      raise(ValidationError, DUPLICATE_REPAYMENT_ID)
    end

    # 入金エラーのチェック
    raise(ValidationError, error_formatter(error)) if error.present?

    # ContractorUser宛: メッセージとメールの送信
    SendReceivePaymentMessageAndEmail.new(contractor, payment_ymd, payment_amount).call

    receive_amount_history = ReceiveAmountHistory.find_by(repayment_id: repayment_id)

    # スタッフ宛: 入金処理でexceededが増えた場合にメールを送信する
    if receive_amount_history.exceeded_occurred_amount > 0
      SendMail.exceeded_payment(contractor, receive_amount_history)
    end

    render json: {
      result: "OK"
    }
  end

  private
    # 画面に返すエラーをRUDY用に変換する
    def error_formatter(error)
      case error
      when I18n.t('error_message.invalid_future_date')
        # 日付が未来日
        'invalid_date'
      when I18n.t('error_message.has_can_repayment_and_applying_change_product_orders')
        # Switchのリクエストがある
        'exist_switch_request'
      else
        p error
        'unexpected_error'
      end
    end
end
