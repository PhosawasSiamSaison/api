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
    @calculate_record_arr = []
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
          calculate_record = CalculatePaymentAndInstallment.create!(
            payment_id: payment.id,
            installment_id: installment.id,
            is_exemption_late_charge: is_exemption_late_charge,
            input_amount: input_amount,
            total_exceeded: contractor.exceeded_amount,
            total_cashback: contractor.cashback_amount,
            subtract_exceeded: payment_subtraction[:exceeded],
            subtract_cashback: payment_subtraction[:cashback],
            payment_ymd: payment_ymd,
            business_ymd: BusinessDay.today_ymd,
            due_ymd: installment.due_ymd
          )
          calculate_record_arr << calculate_record

          # 遅延のみ処理をする
          next unless payment.over_due?

          # 遅損金の支払い残金
          remaining_late_charge = installment.calc_remaining_late_charge(payment_ymd)
          calculate_record.remaining_late_charge = remaining_late_charge

          # update remaining_late_charge to check calculate to make sure that this value not being skip in next line
          calculate_record.save!

          # 遅損金なしは処理しない
          next if remaining_late_charge == 0

          # calculate_late_charges
          create_calculate_late_charges_record(installment, calculate_record)

          # การลบแต่ละจำนวน
          after_remaining_late_charge, after_exceeded, after_cashback, after_input_amount =
            calc_subtract(remaining_late_charge, exceeded, cashback, input_amount)

          # จำนวนเงินที่ต้องจ่าย
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

            calculate_record.exemption_late_charge = remaining_late_charge
            calculate_record.total_exemption_late_charge = total_exemption_late_charge
            calculate_record.save!

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

          # การผ่อนชำระและการอัปเดตประวัติการผ่อนชำระ
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

          calculate_record.update(
            payment_late_charge: payment_late_charge,
            after_remaining_late_charge: after_remaining_late_charge,
            after_input_amount_remaining_late_charge: after_input_amount,
            after_exceeded_remaining_late_charge: after_exceeded,
            after_cashback_remaining_late_charge: after_cashback,
            paid_exceeded_remaining_late_charge: paid_exceeded,
            paid_cashback_remaining_late_charge: paid_cashback,
            paid_total_exceeded: paid_total_exceeded,
            paid_total_cashback: paid_total_cashback
          )
          calculate_record.save!

          break if (input_amount + exceeded + cashback).round(2) == 0
        end

        # 利息と元本の充当
        installments.reload.each do |installment|
          calculate_record = find_calculate_record(installment.id)
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

          calculate_record.update(
            remaining_interest: remaining_interest,
            after_remaining_interest: after_remaining_interest,
            after_input_amount_remaining_interest: input_amount,
            after_exceeded_remaining_interest: after_exceeded,
            after_cashback_remaining_interest: after_cashback,
            paid_exceeded_remaining_interest: paid_exceeded,
            paid_cashback_remaining_interest: paid_cashback,
            # paid_total_exceeded: paid_exceeded,
            # paid_total_cashback: paid_total_cashback
          )

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

          calculate_record.update(
            remaining_principal: remaining_principal,
            after_remaining_principal: after_remaining_principal,
            after_input_amount_remaining_principal: input_amount,
            after_exceeded_remaining_principal: after_exceeded,
            after_cashback_remaining_principal: after_cashback,
            paid_exceeded_remaining_principal: paid_exceeded,
            paid_cashback_remaining_principal: paid_cashback,
            # paid_total_exceeded: paid_exceeded,
            # paid_total_cashback: paid_total_cashback
          )

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

          calculate_record.paid_total_exceeded += paid_exceeded
          calculate_record.paid_total_cashback += paid_cashback
          calculate_record.paid_exceeded_and_cashback_amount = 
            calculate_record.paid_total_exceeded + calculate_record.paid_total_cashback
          calculate_record.gain_exceeded_amount = input_amount
          calculate_record.save!

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
          calculate_record = find_calculate_record(installment.id)
          receive_amount_detail_data[:cashback_occurred_amount] = cashback_amount
          calculate_record.update!(gain_cashback_amount: cashback_amount)
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


      # การสร้างข้อมูลประวัติ
      # แยกเฉพาะงวดที่ได้รับการขัดถู (และยกเว้น)
      @receive_amount_detail_data_arr = receive_amount_detail_data_arr.select {|item|
        # รับเฉพาะรายที่มีจำนวนรายการเริ่มต้นมากกว่า (3)
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
    :is_exemption_late_charge, :receive_amount_detail_data_arr, :repayment_id, :subtraction_repayment,
    :calculate_record_arr

  # 指定の金額から減算をした残りの金額を返す
  # exceeded -> cashback -> input_amount(入金額) の順で target_amount(支払額) から引いていく
  def calc_subtract(target_amount, exceeded, cashback, input_amount)
    # หักเกิน
    if exceeded > 0
      # สมดุล
      subtract_amount = [target_amount, exceeded].min

      # ใช้กับจำนวนเงินเดิม
      target_amount = (target_amount - subtract_amount).round(2).to_f
      exceeded = (exceeded - subtract_amount).round(2).to_f
    end

    # การหักเงินคืน
    if target_amount > 0 && cashback > 0
      # สมดุล
      subtract_amount = [target_amount, cashback].min

      # ใช้กับจำนวนเงินเดิม
      target_amount = (target_amount - subtract_amount).round(2).to_f
      cashback = (cashback - subtract_amount).round(2).to_f
    end

    # ลบจำนวนเงินฝาก
    if target_amount > 0 && input_amount > 0
      # สมดุล
      subtract_amount = [target_amount, input_amount].min

      # ใช้กับจำนวนเงินเดิม
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

  def find_calculate_record(installment_id)
    calculate_record_arr.find do |item|
      item.installment_id == installment_id
    end
  end

  def create_calculate_late_charges_record(installment, calculate_record)
    delay_penalty_rate = installment.order.belongs_to_project_finance? ?
      installment.order.project.delay_penalty_rate : installment.contractor.delay_penalty_rate
      
    calced_delay_penalty_rate = delay_penalty_rate / 100.0

    late_charge_days = installment.calc_late_charge_days(payment_ymd)
    calc_start_ymd = installment.calc_start_ymd(payment_ymd)
    remaining_amount_without_late_charge = installment.calc_remaining_amount_without_late_charge(payment_ymd)
    calced_amount = BigDecimal(remaining_amount_without_late_charge.to_s) * calced_delay_penalty_rate
    calced_days = BigDecimal(late_charge_days.to_s) / 365

    original_late_charge_amount = (calced_amount * calced_days).floor(2).to_f
    calc_paid_late_charge = installment.calc_paid_late_charge(payment_ymd)

    late_charge_start_ymd = installment.calc_late_charge_start_ymd(payment_ymd)
    yesterday_start_ymd =
      late_charge_start_ymd ? Date.parse(late_charge_start_ymd).yesterday.strftime('%Y%m%d') : nil
    paid_late_charge_before_late_charge_start_ymd = late_charge_start_ymd ?
      installment.calc_paid_late_charge(yesterday_start_ymd) : nil

    # calculate_late_charges
    CalculateLateCharge.create!(
      calculate_payment_and_installment_id: calculate_record.id,
      installment_id: installment.id,
      payment_ymd: payment_ymd,
      due_ymd: installment.due_ymd,
      late_charge_start_ymd: late_charge_start_ymd,
      calc_start_ymd: calc_start_ymd,
      late_charge_days: late_charge_days,
      delay_penalty_rate: delay_penalty_rate,
      remaining_amount_without_late_charge: remaining_amount_without_late_charge,
      calced_amount: calced_amount.to_s,
      calced_days: calced_days.to_s,
      original_late_charge_amount: original_late_charge_amount,
      calc_paid_late_charge: calc_paid_late_charge,
      paid_late_charge_before_late_charge_start_ymd: paid_late_charge_before_late_charge_start_ymd,
      calc_late_charge: installment.calc_late_charge(payment_ymd),
      remaining_late_charge: installment.calc_remaining_late_charge(payment_ymd)
    )
  end
end
