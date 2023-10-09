# frozen_string_literal: true

class CancelOrder
  include ErrorInfoModule

  def initialize(order_id, login_user, do_check_error: true, on_rudy: false)
    @order_id = order_id
    @login_user = login_user
    @do_check_error = do_check_error
    @on_rudy = on_rudy
  end

  def call
    if do_check_error

      unless on_rudy
        # 権限がMD/MGRもしくは管理者であること
        errors = check_permission_errors(login_user.md? || login_user.system_admin)
        return { success: false, errors:  errors } if errors.present?
      end

      # エラーがある場合にRUDY用と画面エラー用の値をセットする
      rudy_const, error_locale_key =
        if order.canceled?
          # キャンセル済み
          [ 'already_canceled_order', 'already_canceled_order' ]
        elsif order.is_applying_change_product?
          # Switchの申請あり
          [ 'switched_order', 'is_applying_change_product' ]
        elsif order.rescheduled?
          # リスケ済み
          [ 'rescheduled_order', 'already_rescheduled_order' ]
        elsif order.rescheduled_new_order?
          # リスケで作成されたオーダー
          [ 'reschedule_order', 'rescheduled_new_order' ]
        elsif order.paid_total_amount > 0
          # 消し込み済み
          [ 'paid_order', 'some_amount_has_already_been_paid' ]
        end

      # RUDYの場合はRUDYのエラー定数を返す
      return { success: false, error: rudy_const } if on_rudy && rudy_const
        
      return { success: false, errors: set_errors('error_message.' + error_locale_key) } if error_locale_key
    end

    error = nil
    ActiveRecord::Base.transaction do
      order.update!(canceled_at: Time.zone.now, canceled_user: login_user, uniq_check_flg: nil)

      order.installments.each do |installment|
        installment.update!(deleted: true)
        installment.remove_from_payment
      end

      # เรียก RUDY API (จากหน้าจอเท่านั้น ต้องใช้ Dealer_code)
      error = RudyCancelOrder.new(order).exec if !on_rudy && order.dealer.present?

      raise ActiveRecord::Rollback if error.present?
    end

    if error.blank?
      { success: true }
    else
      { success: false, error: error }
    end
  end

  private
  attr_accessor :login_user, :do_check_error, :on_rudy

  def order
    order ||= Order.find(@order_id)
  end
end
