desc '入金消込1件の取消。'
task :delete_received_confirmation, ['contractor_id'] => :environment do |task, args|

  #cashback,site_reduced_amountの手動調整がさらに必要かを最後に判定するためのフラグ
  adjust_cashback_required = false
  adjust_site_reduced_amount_required = false
  
  #このタスクの実行により影響を受けたレコードにはoperation_updated_atに実行日時が入るようにする
  operation_updated_at = DateTime.now

  #対象received_amount_historyからreceive_amount_detailsを取得
  contractor = Contractor.find(args[:contractor_id])
  receive_amount_history = contractor.receive_amount_histories.order(:created_at).last
  # そのContractorの入金履歴がない際はタスクを終了させる
  if !receive_amount_history.present?
    p '当該Contractorの入金履歴が見つかりません'
    next
  end
  receive_amount_details = receive_amount_history.receive_amount_details
  
  # receive_amount_detailsテーブル作成前の入金消込は扱えないので、当該レコードが見つからない際はタスクを終了させる
  if receive_amount_details.length == 0 
    p '当該のreceive_amount_detailsレコードが見つかりません。'
    next
  end

  ActiveRecord::Base.transaction do
    # 取得したreceive_amount_detail毎にロールバック処理をする
    receive_amount_details.each do |receive_amount_detail|

      # 0バーツ消し込みの取消時は、receive_amount_detailのorderへの消込額関係の値はnullなので処理を分ける
      if receive_amount_detail.payment.present?
        # paymentsテーブルの処理
        payment = receive_amount_detail.payment
        payment.paid_up_ymd = nil
        payment.paid_up_operated_ymd = nil
        payment.paid_total_amount -= (receive_amount_detail.paid_principal + 
          receive_amount_detail.paid_interest + receive_amount_detail.paid_late_charge)
        payment.paid_exceeded -= receive_amount_detail.exceeded_paid_amount
        payment.paid_cashback -= receive_amount_detail.cashback_paid_amount
        payment.status = Date.parse(payment.due_ymd, '%Y%m%d') < BusinessDay.today ? :over_due : :next_due
        payment.operation_updated_at = operation_updated_at
        payment.save!

        # ordersテーブルの処理
        order = receive_amount_detail.order
        order.update!(paid_up_ymd: nil, operation_updated_at: operation_updated_at)

        # installmentテーブルの処理
        installment = receive_amount_detail.installment
        # installmentがAdjust Repaymentされていた場合は整合性が取れなくなるので、手動対応とする
        if installment.adjust_repayment_histories.length > 0
          p 'この入金にはadjustされたinstallmentが含まれているので、手動対応にて入金取消対応をしてください'
          raise ActiveRecord::Rollback
        end
        installment.paid_up_ymd = nil
        installment.paid_principal -= receive_amount_detail.paid_principal
        installment.paid_interest -= receive_amount_detail.paid_interest
        installment.paid_late_charge -= receive_amount_detail.paid_late_charge
        # adjust repayment対応以前のはinstallment.used_exceededとinstallment.used_cashbackが記録されていないのでそのままにする
        if installment.used_exceeded.present?
          installment.used_exceeded -= receive_amount_detail.exceeded_paid_amount
        end
        if installment.used_cashback.present?
          installment.used_cashback -= receive_amount_detail.cashback_paid_amount
        end
        # reduced_site_limitには一旦0を入れて、調整が必要な時は手動調整する
        installment.reduced_site_limit = 0;
        installment.operation_updated_at = operation_updated_at
        installment.save!

        # installment_historiesテーブルの処理
        last_installment_history = installment.installment_histories.order(:to_ymd).last
        last_installment_history.paid_principal -= receive_amount_detail.paid_principal
        last_installment_history.paid_interest -= receive_amount_detail.paid_interest
        last_installment_history.paid_late_charge -= receive_amount_detail.paid_late_charge
        last_installment_history.save!

        # 操作対象のinstallment_historyが一つの場合は下記の処理は行わない
        if used_two_installment_histories?(installment)
          second_installment_history = installment.installment_histories.order(:to_ymd).second_to_last()
          # 最新のレコードを削除
          last_installment_history.delete
          # 一つ前のレコードのto_ymdを99991231に
          second_installment_history.update!(to_ymd: '99991231', operation_updated_at: operation_updated_at)
        end

        # 0バーツ消込ではない時のcontractorsテーブルの処理
        contractor = receive_amount_detail.contractor
        contractor.pool_amount += (receive_amount_detail.exceeded_paid_amount - receive_amount_detail.exceeded_occurred_amount)
        contractor.operation_updated_at = operation_updated_at
        contractor.save!

        # cashback_historiesテーブルの処理
        if receive_amount_detail.cashback_paid_amount != 0 || receive_amount_detail.cashback_occurred_amount != 0
          target_cashback_history = CashbackHistory.find_by(receive_amount_history_id: receive_amount_history.id)
          contractors_cashback_histories = contractor.cashback_histories
          # cashbackと入金履歴の紐付け対応以前のもの、及び当該cashback以降cashbackの増減があるものは手動対応が必要
          if !target_cashback_history.nil? && (contractor.latest_cashback == target_cashback_history)
            target_cashback_history.update!(deleted: true)
            contractors_cashback_histories.order(:id).last.update!(latest: true)
          else
            adjust_cashback_required = true
          end
        end

        # installment.site_reduced_amount修正の必要性が生じたかの判定
        if receive_amount_detail.order.site_order? && receive_amount_detail.installment.paid_principal != 0
          adjust_site_reduced_amount_required = true
        end

      else
        # 0バーツ消込の時のcontractorsテーブルの処理
        contractor = receive_amount_detail.contractor
        contractor.pool_amount -= receive_amount_detail.exceeded_occurred_amount
        contractor.operation_updated_at = operation_updated_at
        contractor.save!
      end
        
      # receive_amount_detailの処理が終わったらreceive_amount_detaillを削除
      receive_amount_detail.update!(deleted: true, operation_updated_at: operation_updated_at)
    end

    # 全てのreceive_amount_detailの処理が終わったらreceive_amount_historyを削除
    receive_amount_history.update!(deleted: true, operation_updated_at: operation_updated_at)

    if adjust_cashback_required
      p '手動対応:Cashback調整が必要です。'
    end

    if adjust_site_reduced_amount_required
      p '手動対応:site_reduced_amount調整が必要です。'
    end

    p '入金消込取消が完了しました。'

  end

  rescue => e
    print '失敗：'
    puts e
  end

  def used_two_installment_histories?(installment)
    # purchase_ymdと同日付で入金消し込みをした際など、installment_historyが一つしかない場合はfalse
    return false unless installment.installment_histories.length >= 2
    last_installment_history = installment.installment_histories.order(:to_ymd).last
    second_installment_history = installment.installment_histories.order(:to_ymd).second_to_last()
    # 同日付で2回消し込んだ場合も操作対象のinstallment_historyは一つだけなのでfalse
    (last_installment_history.paid_principal == 0 || last_installment_history.paid_principal == second_installment_history.paid_principal) &&
    (last_installment_history.paid_interest == 0 || last_installment_history.paid_interest == second_installment_history.paid_interest) &&
    (last_installment_history.paid_late_charge == 0 || last_installment_history.paid_late_charge == second_installment_history.paid_late_charge)
  end