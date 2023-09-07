# frozen_string_literal: true

class AppropriatePaymentToInstallments
  def initialize(contractor, payment_ymd, payment_amount, create_user, comment, is_exemption = false, repayment_id: nil, subtraction_repayment: false)
    @contractor = contractor
    @payment_ymd = payment_ymd
    @payment_amount = payment_amount
    @create_user = create_user
    @comment = comment
    @is_exemption_late_charge = is_exemption
    @repayment_id = repayment_id
    @subtraction_repayment = subtraction_repayment

    # 履歴データ作成の入れ物
    @receive_amount_detail_data_arr = []
  end

  def call
    # 日付の未来日チェック
    return { error: I18n.t('error_message.invalid_future_date') } if BusinessDay.today_ymd < payment_ymd

    # 消し込み可能かつ商品変更の申請をされているオーダーがある場合はエラー
    if contractor.has_can_repayment_and_applying_change_product_orders?
      return { error: I18n.t('error_message.has_can_repayment_and_applying_change_product_orders') }
    end

    raise if subtraction_repayment && payment_amount != 0

    ActiveRecord::Base.transaction do
      input_amount = payment_amount.to_f

      paid_total_exceeded = 0
      paid_total_cashback = 0

      # 免除した遅損金の合計
      total_exemption_late_charge = 0

      # 減算額の算出
      payment_subtractions =
        CalcPaymentSubtractions.new(contractor, payment_ymd, is_exemption_late_charge).call

      # Payment
      contractor.payments.appropriate_payments.each do |payment|
        payment_subtraction = payment_subtractions[payment.id]

        exceeded = payment_subtraction[:exceeded]
        cashback = payment_subtraction[:cashback]

        break if (input_amount + exceeded + cashback).round(2) == 0

        # 対象のinstallmentsをソートして取得
        installments = payment.installments.payable_installments.appropriation_sort

        # 履歴データの初期化
        installments.each do |installment|
          receive_amount_detail_data_arr.push({
            installment_id: installment.id,
            exceeded_paid_amount: 0,
            cashback_paid_amount: 0,
          })
        end

        # 遅損金の充当
        installments.each do |installment|
          # 遅延のみ処理をする
          next unless payment.over_due?

          # 遅損金の支払い残金
          remaining_late_charge = installment.calc_remaining_late_charge(payment_ymd)
          # 遅損金なしは処理しない
          next if remaining_late_charge == 0

          # 各金額の減算処理
          after_remaining_late_charge, after_exceeded, after_cashback, after_input_amount =
            calc_subtract(remaining_late_charge, exceeded, cashback, input_amount)

          # 支払う金額
          payment_late_charge = (remaining_late_charge - after_remaining_late_charge).round(2).to_f

          # 履歴データの取得
          receive_amount_detail_data = find_receive_amount_detail_data(installment.id)

          # 遅損金の支払いの免除
          if payment_late_charge > 0 && is_exemption_late_charge
            # 免除履歴のレコードを作成
            installment.exemption_late_charges.create!(amount: remaining_late_charge)

            # 履歴データの作成
            receive_amount_detail_data[:waive_late_charge] = remaining_late_charge

            total_exemption_late_charge += remaining_late_charge
            next
          end

          input_amount = after_input_amount

          # 支払い分を算出
          paid_exceeded = exceeded - after_exceeded
          # 減算した値で更新
          exceeded = after_exceeded

          # 支払い分を算出
          paid_cashback = cashback - after_cashback
          # 減算した値で更新
          cashback = after_cashback


          # 支払い済みに足す
          installment.paid_late_charge += payment_late_charge
          # Adjust Repayment対応前のinstallmentデータのカラムはNULLの想定なので追加しない
          installment.used_exceeded += paid_exceeded unless installment.used_exceeded.nil?
          installment.used_cashback += paid_cashback unless installment.used_cashback.nil?

          # InstallmentのとInstallmentHistoryの更新
          installment.save_with_history(payment_ymd)

          # Payment を更新
          payment.paid_total_amount += payment_late_charge
          payment.paid_exceeded += paid_exceeded
          payment.paid_cashback += paid_cashback
          # 支払ったexceededの合計
          paid_total_exceeded += paid_exceeded
          # 支払ったcashbackの合計
          paid_total_cashback += paid_cashback

          # 履歴データ
          receive_amount_detail_data[:paid_late_charge] = payment_late_charge if payment_late_charge > 0
          receive_amount_detail_data[:exceeded_paid_amount] += paid_exceeded
          receive_amount_detail_data[:cashback_paid_amount] += paid_cashback

          break if (input_amount + exceeded + cashback).round(2) == 0
        end

        # 利息と元本の充当
        installments.reload.each do |installment|
          ## 利息
          # 利息の支払い残金
          remaining_interest = installment.remaining_interest

          # 各金額の減算処理
          after_remaining_interest, after_exceeded, after_cashback, input_amount =
            calc_subtract(remaining_interest, exceeded, cashback, input_amount)

          # 支払う利息金額
          payment_interest = (remaining_interest - after_remaining_interest).round(2).to_f

          # 支払い分を算出
          paid_exceeded = exceeded - after_exceeded
          # 減算した値で更新
          exceeded = after_exceeded

          # 支払い分を算出
          paid_cashback = cashback - after_cashback
          # 減算した値で更新
          cashback = after_cashback

          # 支払い済みに足す
          installment.paid_interest += payment_interest


          ## 元本
          # 元本の支払い残金
          remaining_principal = installment.remaining_principal

          # 各金額の減算処理
          after_remaining_principal, after_exceeded, after_cashback, input_amount =
            calc_subtract(remaining_principal, exceeded, cashback, input_amount)

          # 支払う元本金額
          payment_principal = (remaining_principal - after_remaining_principal).round(2).to_f

          # 支払い分を算出
          paid_exceeded += (exceeded - after_exceeded)
          # 減算した値で更新
          exceeded = after_exceeded

          # 支払い分を算出
          paid_cashback += (cashback - after_cashback)
          # 減算した値で更新
          cashback = after_cashback

          # 支払い済みに足す
          installment.paid_principal += payment_principal

          # Adjust Repayment対応前のinstallmentデータのカラムはNULLの想定なので追加しない
          installment.used_exceeded += paid_exceeded unless installment.used_exceeded.nil?
          installment.used_cashback += paid_cashback unless installment.used_cashback.nil?

          # installmentの支払い完了
          if installment.paid_principal == installment.principal
            # 支払い完了日に入金日を入れる
            installment.paid_up_ymd = payment_ymd
          end


          # InstallmentのとInstallmentHistoryの更新
          installment.save_with_history(payment_ymd)


          # Siteオーダーの元本の消し込み時にはSite Credit Limitを減額する
          # remaining_balanceを算出するためにsaveの後に実行する
          if installment.order.site_order? && payment_principal > 0
            ReduceSiteLimit.new.call(installment, payment_principal)

            # RUDYへ減額値を通知
            RudyUpdateSiteLimit.new(installment.order).exec
          end


          # Payment
          payment.paid_total_amount += (payment_interest + payment_principal).round(2)
          payment.paid_exceeded += paid_exceeded
          payment.paid_cashback += paid_cashback

          # 支払ったexceededの合計
          paid_total_exceeded += paid_exceeded
          # 支払ったcashbackの合計
          paid_total_cashback += paid_cashback

          # 履歴データの取得
          receive_amount_detail_data = find_receive_amount_detail_data(installment.id)
          receive_amount_detail_data[:paid_interest] = payment_interest if payment_interest > 0
          receive_amount_detail_data[:paid_principal] = payment_principal if payment_principal > 0
          receive_amount_detail_data[:exceeded_paid_amount] += paid_exceeded
          receive_amount_detail_data[:cashback_paid_amount] += paid_cashback

          break if (input_amount + exceeded + cashback).round(2) == 0
        end

        # 全ての支払いが完了していたら
        if installments.reload.all?(&:paid?)
          # 支払い済みのデータをセットする
          payment.status = 'paid'
          payment.paid_up_ymd = payment_ymd
          payment.paid_up_operated_ymd = today_ymd
        end

        payment.save!

        # paymentの支払いが完了しなければ、後続のpaymentも処理をしない
        break unless payment.paid?
      end

      paid_exceeded_and_cashback_amount = (paid_total_exceeded + paid_total_cashback).round(2)

      if subtraction_repayment
        # 自動消し込みでExceededとCashbackを使用しなかった場合は終了する
        return { error: 'failed_subtraction_repayment' } if paid_exceeded_and_cashback_amount == 0
      end

      # Receive Amount History
      receive_amount_history = ReceiveAmountHistory.create!(contractor: contractor,
        receive_ymd: payment_ymd,
        receive_amount: payment_amount,
        comment: comment,
        create_user: create_user,
        exemption_late_charge: is_exemption_late_charge ? total_exemption_late_charge : nil,
        repayment_id: repayment_id,
      )


      # 使用したキャッシュバックの履歴を作成
      if paid_total_cashback > 0
        # キャッシュバック使用の履歴を作成
        contractor.create_use_cashback_history(
          paid_total_cashback, payment_ymd, receive_amount_history_id: receive_amount_history.id
        )
      end


      # 支払いが完了したOrderの更新
      contractor.orders.includes(:installments).payable_orders.each do |order|
        next unless order.installments.all?(&:paid?)

        order.update!(paid_up_ymd: payment_ymd)

        # キャッシュバック
        if order.can_gain_cashback?
          # キャッシュバック金額を算出
          cashback_amount = order.calc_cashback_amount

          # キャッシュバック獲得の履歴を作成
          contractor.create_gain_cashback_history(
            cashback_amount, payment_ymd, order.id, receive_amount_history_id: receive_amount_history.id
          )

          # 履歴データ
          installment = order.installments.first
          receive_amount_detail_data = find_receive_amount_detail_data(installment.id)
          receive_amount_detail_data[:cashback_occurred_amount] = cashback_amount
        end

        # RUDY API を呼ぶ
        # 再約定で実行する場合はdealerを考慮する
        RudyBillingPayment.new(order).exec if !order.rescheduled_new_order?
      end

      # 使用したExceededを引く
      contractor.pool_amount -= paid_total_exceeded
      # 余った入金額をExceededへ入れる
      contractor.pool_amount += input_amount

      # 免除のチェックがあればカウントをあげる
      contractor.exemption_late_charge_count += 1 if is_exemption_late_charge

      contractor.check_payment = false

      contractor.save!


      # 履歴データの作成
      # 消し込み(と免除)のあったinstallmentのみを抽出
      @receive_amount_detail_data_arr = receive_amount_detail_data_arr.select {|item|
        # 初期項目数(3つ)より多いものだけを取得
        item.keys.count > 3
      }

      # 消し込みも免除もなければdetail_dataは空になる
      # 免除フラグがある場合はlate_charge(払うべき遅損金)の値は0になる
      # Eceededのみが作成されるパターン(消し込みも免除もない場合)
      if receive_amount_detail_data_arr.blank? && input_amount > 0
        ReceiveAmountDetail.create!(
          receive_amount_history: receive_amount_history,
          contractor: contractor,
          repayment_ymd: payment_ymd,
          exceeded_occurred_amount: input_amount,
          exceeded_occurred_ymd: payment_ymd,
          tax_id: contractor.tax_id,
          th_company_name: contractor.th_company_name,
          en_company_name: contractor.en_company_name,
        )
      else
        last_row = receive_amount_detail_data_arr.last

        receive_amount_detail_data_arr.each do |data|
          installment = Installment.find(data[:installment_id])

          # 最後の消し込みのinstallmentのみに値をセットする
          exceeded_occurred_amount =
            last_row[:installment_id] == data[:installment_id] ? input_amount : 0

          ReceiveAmountDetail.create!(
            receive_amount_history: receive_amount_history,
            contractor: contractor,
            installment: installment,
            repayment_ymd: payment_ymd,

            order_number: installment.order.order_number,
            dealer_name: installment.order.dealer&.dealer_name,
            dealer_type: installment.order.dealer&.dealer_type,
            tax_id: contractor.tax_id,
            th_company_name: contractor.th_company_name,
            en_company_name: contractor.en_company_name,
            bill_date: installment.order.bill_date,
            site_code: installment.order.site&.site_code,
            site_name: installment.order.site&.site_name,
            product_name: installment.order.product&.product_name,
            installment_number: installment.installment_number,
            due_ymd: installment.due_ymd,
            input_ymd: installment.order.input_ymd,
            switched_date: installment.order.product_changed_at,
            rescheduled_date: installment.order.rescheduled_at,

            principal: installment.principal,
            interest: installment.interest,
            late_charge: is_exemption_late_charge ? 0 : installment.calc_late_charge(payment_ymd),

            paid_principal: data[:paid_principal] || 0,
            paid_interest: data[:paid_interest] || 0,
            paid_late_charge: data[:paid_late_charge] || 0,

            # total paid
            total_principal: installment.paid_principal,
            total_interest: installment.paid_interest,
            total_late_charge: installment.paid_late_charge,

            exceeded_occurred_amount: exceeded_occurred_amount,
            exceeded_occurred_ymd: exceeded_occurred_amount > 0 ? payment_ymd : nil,
            exceeded_paid_amount: data[:exceeded_paid_amount] || 0,

            cashback_occurred_amount: data[:cashback_occurred_amount] || 0,
            cashback_paid_amount: data[:cashback_paid_amount] || 0,

            waive_late_charge: data[:waive_late_charge] || 0,

            payment: installment.payment,
            order: installment.order,
            dealer: installment.order.dealer,
          )
        end
      end

      return { error: nil, paid_exceeded_and_cashback_amount: paid_exceeded_and_cashback_amount }
    end
  end

  private
  attr_reader :contractor, :payment_ymd, :payment_amount, :create_user, :comment,
    :is_exemption_late_charge, :receive_amount_detail_data_arr, :repayment_id, :subtraction_repayment

  # 指定の金額から減算をした残りの金額を返す
  # exceeded -> cashback -> input_amount(入金額) の順で target_amount(支払額) から引いていく
  def calc_subtract(target_amount, exceeded, cashback, input_amount)
    # exceededの減算
    if exceeded > 0
      # 差引額
      subtract_amount = [target_amount, exceeded].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      exceeded = (exceeded - subtract_amount).round(2).to_f
    end

    # cashbackの減算
    if target_amount > 0 && cashback > 0
      # 差引額
      subtract_amount = [target_amount, cashback].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      cashback = (cashback - subtract_amount).round(2).to_f
    end

    # 入金額の減算
    if target_amount > 0 && input_amount > 0
      # 差引額
      subtract_amount = [target_amount, input_amount].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      input_amount = (input_amount - subtract_amount).round(2).to_f
    end

    [target_amount, exceeded, cashback, input_amount]
  end

  def today_ymd
    @today_ymd ||= BusinessDay.today_ymd
  end

  def find_receive_amount_detail_data(installment_id)
    receive_amount_detail_data_arr.find do |item|
      item[:installment_id] == installment_id
    end
  end
end
