# frozen_string_literal: true

class AppropriateProjectOrders
  def call(project_phase_site, payment_ymd, payment_amount, create_user, comment, is_exemption_late_charge)
    ActiveRecord::Base.transaction do
      input_amount = payment_amount.to_f

      # 免除した遅損金の合計
      total_exemption_late_charge = 0

      # 履歴データ作成の入れ物
      @receive_amount_detail_data_arr = []
      @calculate_record_arr = []

      # 履歴データの初期化
      project_phase_site.orders.each do |order|
        receive_amount_detail_data_arr.push({
          order_id: order.id,
        })
      end

      # 遅損金の充当
      project_phase_site.payment_list_orders_only_input_ymd.each do |order|
        installment = order.installments.first
        calculate_record = CalculateProjectAndInstallment.create!(
          # payment_id: payment.id,
          installment_id: installment.id,
          is_exemption_late_charge: is_exemption_late_charge,
          input_amount: input_amount,
          # total_exceeded: contractor.exceeded_amount,
          # total_cashback: contractor.cashback_amount,
          # subtract_exceeded: payment_subtraction[:exceeded],
          # subtract_cashback: payment_subtraction[:cashback],
          payment_ymd: payment_ymd,
          business_ymd: BusinessDay.today_ymd,
          due_ymd: installment.due_ymd
        )
        calculate_record_arr << calculate_record

        # 遅延のみ処理をする
        next unless installment.over_due?(payment_ymd)

        # 遅損金の支払い残金
        remaining_late_charge = installment.calc_remaining_late_charge(payment_ymd)
        calculate_record.remaining_late_charge = remaining_late_charge

        # update remaining_late_charge to check calculate to make sure that this value not being skip in next line
        calculate_record.save!
        # 遅損金なしは処理しない
        next if remaining_late_charge == 0

         # calculate_late_charges
         create_calculate_late_charges_record(installment, calculate_record, payment_ymd)

        # 各金額の減算処理
        after_remaining_late_charge, after_input_amount =
          calc_subtract(remaining_late_charge, input_amount)

        # 支払う金額
        payment_late_charge = (remaining_late_charge - after_remaining_late_charge).round(2).to_f

        # 履歴データの取得
        receive_amount_detail_data = find_receive_amount_detail_data(order.id)

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

        # 支払い済みに足す
        installment.paid_late_charge += payment_late_charge
        project_phase_site.paid_total_amount += payment_late_charge

        calculate_record.paid_total_amount += payment_late_charge

        # InstallmentのとInstallmentHistoryの更新
        installment.save_with_history(payment_ymd)

        # 履歴データ
        receive_amount_detail_data[:paid_late_charge] = payment_late_charge if payment_late_charge > 0

        calculate_record.update(
          payment_late_charge: payment_late_charge,
          after_remaining_late_charge: after_remaining_late_charge,
          after_input_amount_remaining_late_charge: after_input_amount,
          paid_late_charge: payment_late_charge
        )
        calculate_record.save!

        break if input_amount == 0
      end

      # 利息と元本の充当
      project_phase_site.payment_list_orders_only_input_ymd.each do |order|
        installment = order.installments.first

        calculate_record = find_calculate_record(installment.id)

        ## 利息
        # 利息の支払い残金
        remaining_interest = installment.remaining_interest

        # 各金額の減算処理
        after_remaining_interest, input_amount =
          calc_subtract(remaining_interest, input_amount)

        # 支払う利息金額
        payment_interest = (remaining_interest - after_remaining_interest).round(2).to_f

        # 支払い済みに足す
        installment.paid_interest += payment_interest

        calculate_record.paid_total_amount += payment_interest

        calculate_record.update(
          remaining_interest: remaining_interest,
          after_remaining_interest: after_remaining_interest,
          after_input_amount_remaining_interest: input_amount,
          paid_interest: payment_interest
          # after_exceeded_remaining_interest: after_exceeded,
          # after_cashback_remaining_interest: after_cashback,
          # paid_exceeded_remaining_interest: paid_exceeded,
          # paid_cashback_remaining_interest: paid_cashback,
          # paid_total_exceeded: paid_exceeded,
          # paid_total_cashback: paid_total_cashback
        )
        calculate_record.save!

        ## 元本
        # 元本の支払い残金
        remaining_principal = installment.remaining_principal

        # 各金額の減算処理
        after_remaining_principal, input_amount =
          calc_subtract(remaining_principal, input_amount)

        # 支払う元本金額
        payment_principal = (remaining_principal - after_remaining_principal).round(2).to_f

        # 支払い済みに足す
        installment.paid_principal += payment_principal
        project_phase_site.paid_total_amount += (payment_interest + payment_principal).round(2)

        calculate_record.paid_total_amount += payment_principal

        calculate_record.update(
          remaining_principal: remaining_principal,
          after_remaining_principal: after_remaining_principal,
          after_input_amount_remaining_principal: input_amount,
          paid_principal: payment_principal
          # after_exceeded_remaining_principal: after_exceeded,
          # after_cashback_remaining_principal: after_cashback,
          # paid_exceeded_remaining_principal: paid_exceeded,
          # paid_cashback_remaining_principal: paid_cashback,
          # paid_total_exceeded: paid_exceeded,
          # paid_total_cashback: paid_total_cashback
        )
        calculate_record.save!

        # installmentの支払い完了
        if installment.paid_principal == installment.principal
          # 支払い完了日に入金日を入れる
          installment.paid_up_ymd = payment_ymd
        end

        # InstallmentのとInstallmentHistoryの更新
        installment.save_with_history(payment_ymd)

        # 履歴データの取得
        receive_amount_detail_data = find_receive_amount_detail_data(order.id)
        receive_amount_detail_data[:paid_interest] = payment_interest if payment_interest > 0
        receive_amount_detail_data[:paid_principal] = payment_principal if payment_principal > 0

        # calculate_record.refund_amount = input_amount
        @lasted_installment_id = installment.id
        calculate_record.save!
        break if input_amount == 0
      end


      # 履歴データの作成
      # 消し込み(と免除)のあったinstallmentのみを抽出
      @receive_amount_detail_data_arr = receive_amount_detail_data_arr.select {|item|
        # 初期項目数(1つ)より多いものだけを取得
        item.keys.count > 1
      }

      # 支払いが完了したOrderの更新
      project_phase_site.orders.each do |order|
        next unless order.installments.all?(&:paid?)

        order.update!(paid_up_ymd: payment_ymd)
      end

      # refundに残金を追加する
      project_phase_site.refund_amount += input_amount

      calculate_record = find_calculate_record(lasted_installment_id)
      calculate_record.refund_amount = input_amount
      calculate_record.save!

      # 免除のチェックがあればカウントをあげる
      if is_exemption_late_charge
        project_phase_site.contractor.project_exemption_late_charge_count += 1
      end

      project_phase_site.save!

      # Receive Amount History
      receive_amount_history = ProjectReceiveAmountHistory.create!(
        contractor: project_phase_site.contractor,
        project_phase_site: project_phase_site,
        receive_ymd: payment_ymd, receive_amount: payment_amount, comment: comment,
        create_user: create_user,
        exemption_late_charge: is_exemption_late_charge ? total_exemption_late_charge : nil
      )
    end
  end

  private
  attr_reader :receive_amount_detail_data_arr, :calculate_record_arr, :lasted_installment_id

  def find_receive_amount_detail_data(order_id)
    receive_amount_detail_data_arr.find do |item|
      item[:order_id] == order_id
    end
  end

  # 指定の金額から減算をした残りの金額を返す
  def calc_subtract(target_amount, input_amount)
    # 入金額の減算
    if target_amount > 0 && input_amount > 0
      # 差引額
      subtract_amount = [target_amount, input_amount].min

      # 元の額へ適用する
      target_amount = (target_amount - subtract_amount).round(2).to_f
      input_amount = (input_amount - subtract_amount).round(2).to_f
    end

    [target_amount, input_amount]
  end

  def find_calculate_record(installment_id)
    calculate_record_arr.find do |item|
      item.installment_id == installment_id
    end
  end

  def create_calculate_late_charges_record(installment, calculate_record, payment_ymd)
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
    CalculateProjectLateCharge.create!(
      calculate_project_and_installment_id: calculate_record.id,
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