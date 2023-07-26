# frozen_string_literal: true

class AppropriateProjectOrders
  def call(project_phase_site, payment_ymd, payment_amount, create_user, comment, is_exemption_late_charge)
    ActiveRecord::Base.transaction do
      input_amount = payment_amount.to_f

      # 免除した遅損金の合計
      total_exemption_late_charge = 0

      # 履歴データ作成の入れ物
      @receive_amount_detail_data_arr = []

      # 履歴データの初期化
      project_phase_site.orders.each do |order|
        receive_amount_detail_data_arr.push({
          order_id: order.id,
        })
      end

      # 遅損金の充当
      project_phase_site.payment_list_orders_only_input_ymd.each do |order|
        installment = order.installments.first

        # 遅延のみ処理をする
        next unless installment.over_due?(payment_ymd)

        # 遅損金の支払い残金
        remaining_late_charge = installment.calc_remaining_late_charge(payment_ymd)
        # 遅損金なしは処理しない
        next if remaining_late_charge == 0

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
          next
        end

        input_amount = after_input_amount

        # 支払い済みに足す
        installment.paid_late_charge += payment_late_charge
        project_phase_site.paid_total_amount += payment_late_charge

        # InstallmentのとInstallmentHistoryの更新
        installment.save_with_history(payment_ymd)

        # 履歴データ
        receive_amount_detail_data[:paid_late_charge] = payment_late_charge if payment_late_charge > 0

        break if input_amount == 0
      end

      # 利息と元本の充当
      project_phase_site.payment_list_orders_only_input_ymd.each do |order|
        installment = order.installments.first

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
  attr_reader :receive_amount_detail_data_arr

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
end