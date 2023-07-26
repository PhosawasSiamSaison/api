# frozen_string_literal: true

class Jv::RescheduleController < ApplicationController
  include CsvModule

  before_action :auth_user

  def contractor
    contractor = Contractor.find(params.fetch(:contractor_id))

    render json: {
      success: true,
      contractor: {
        tax_id: contractor.tax_id,
        th_company_name: contractor.th_company_name,
        en_company_name: contractor.en_company_name,
        contractor_type: contractor.contractor_type_label[:label],
      }
    }
  end

  def reschedule_total_amount
    contractor = Contractor.find(params.fetch(:contractor_id))
    exec_ymd   = params.fetch(:exec_ymd)
    # 対象外のオーダーは除外する
    orders = target_orders(contractor).find(params.fetch(:order_ids, []))
    orders = Order.where(id: orders.map(&:id))

    remainings = orders.calc_remainings(exec_ymd)

    render json: {
      success: true,
      principal:                remainings[:principal],
      interest:                 remainings[:interest],
      late_charge:              remainings[:late_charge],
      interest_and_late_charge: remainings[:interest_and_late_charge],
      total_amount:             remainings[:total_balance],
    }
  end

  def order_list
    contractor = Contractor.find(params.fetch(:contractor_id))
    # 対象のオーダーを取得
    orders = target_orders(contractor)
    # 実行日
    exec_ymd = params.fetch(:exec_ymd)

    render json: {
      success: true,
      orders: orders.map { |order|
        {
          id:           order.id,
          order_number: order.order_number,
          dealer: {
            id:          order.dealer&.id,
            dealer_code: order.dealer&.dealer_code,
            dealer_name: order.dealer&.dealer_name,
            dealer_type: order.dealer&.dealer_type_label || Dealer.new.dealer_type_label,
          },
          input_ymd:      order.input_ymd,
          principal:      order.remaining_principal,
          interest:       order.remaining_interest,
          late_charge:    order.calc_remaining_late_charge(exec_ymd),
          total_amount:   order.calc_remaining_balance(exec_ymd),
          can_reschedule: order.can_reschedule?
        }
      }
    }
  end

  def confirmation
    contractor             = Contractor.find(params.fetch(:contractor_id))
    exec_ymd               = params.fetch(:exec_ymd)
    reschedule_order_count = params.fetch(:reschedule_order_count, nil)
    fee_order_count        = params.fetch(:fee_order_count, nil)
    no_interest            = params.fetch(:no_interest).to_s == 'true'

    reschedule_product = Product.reschedule_product(reschedule_order_count, no_interest)
    fee_product        = Product.fee_product(fee_order_count)

    # 対象外のオーダーは除外する
    orders = target_orders(contractor).find(params.fetch(:order_ids))
    orders = Order.where(id: orders.map(&:id))

    if !orders.all?(&:can_reschedule?)
      # リスケできないオーダーがあればエラー
      raise ActiveRecord::StaleObjectError
    end

    # 新オーダーの購入金額
    new_order_purchase_amount = orders.remaining_principal

    # Fee Orderの購入金額
    fee_order_purchase_amount = orders.calc_remaining_interest_and_late_charge(exec_ymd)

    # 新しいスケジュールの算出
    new_order_installments =
      RescheduleNewSchedule.new.call(new_order_purchase_amount, reschedule_product)

    fee_order_installments =
      RescheduleNewSchedule.new.call(fee_order_purchase_amount, fee_product)

    total_installments = calc_total_installments(new_order_installments, fee_order_installments)

    # リスケ後の支払額の合計
    rescheduled_total_amount =
      (new_order_installments[:total_amount] + fee_order_installments[:total_amount]).round(2)

    remainings = orders.calc_remainings(exec_ymd)

    render json: {
      success: true,
      principal:                remainings[:principal],
      interest_and_late_charge: remainings[:interest_and_late_charge],
      reschedule_amount:        remainings[:total_balance],
      new_order_installments:   new_order_installments,
      fee_order_installments:   fee_order_installments,
      total_installments:       total_installments,
      new_order_interest_list:  RescheduleOrderInterestList.new.list,
    }
  end

  def register
    contractor_id = params.fetch(:contractor_id)
    exec_ymd      = params.fetch(:exec_ymd)
    order_ids     = params.fetch(:order_ids)

    reschedule_order_count = params.fetch(:reschedule_order_count, nil)
    fee_order_count        = params.fetch(:fee_order_count, nil)
    no_interest = params.fetch(:no_interest).to_s == 'true'

    set_credit_limit_to_zero = params.fetch(:set_credit_limit_to_zero, false)
    rescheduled_user = login_user

    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    errors = RescheduleOrders.new.call(contractor_id, exec_ymd, order_ids,
      reschedule_order_count.to_i, fee_order_count.to_i, no_interest, set_credit_limit_to_zero,
      rescheduled_user)

    if errors.blank?
      render json: { success: true }
    else
      render json: { success: false, errors: errors }
    end
  end

  def order_detail
    order = Order.find(params[:order_id])

    render json: {
      success: true,
      order: format_jv_order_detail(order)
    }
  end

  def download_csv
    contractor             = Contractor.find(params.fetch(:contractor_id))
    exec_ymd               = params.fetch(:exec_ymd)
    reschedule_order_count = params.fetch(:reschedule_order_count, nil)
    fee_order_count        = params.fetch(:fee_order_count, nil)
    no_interest            = params.fetch(:no_interest).to_s == 'true'
    order_ids              = params.fetch(:order_ids, [])

    reschedule_product = Product.reschedule_product(reschedule_order_count, no_interest)
    fee_product        = Product.fee_product(fee_order_count)

    # 対象外のオーダーは除外する
    orders = target_orders(contractor).find(order_ids)
    orders = Order.where(id: orders.map(&:id))

    if !orders.all?(&:can_reschedule?)
      # リスケできないオーダーがあればエラー
      raise ActiveRecord::StaleObjectError
    end

    # 新オーダーの購入金額
    new_order_purchase_amount = orders.remaining_principal

    # Fee Orderの購入金額
    fee_order_purchase_amount = orders.calc_remaining_interest_and_late_charge(exec_ymd)

    # 新しいスケジュールの算出
    new_order_installments =
      RescheduleNewSchedule.new.call(new_order_purchase_amount, reschedule_product)

    fee_order_installments =
      RescheduleNewSchedule.new.call(fee_order_purchase_amount, fee_product)

    total_installments = calc_total_installments(new_order_installments, fee_order_installments)

    send_reschedule_csv(orders, exec_ymd, new_order_installments, fee_order_installments, total_installments)
  end

  private
  def target_orders(contractor)
    contractor.orders.inputed_ymd.not_fee_orders.payable_orders
  end

  def calc_total_installments(new_order_installments, fee_order_installments)
    # 返却用の変数
    schedule = []

    # scheduleに新しいオーダーの情報を入れていく
    new_order_installments[:schedule].each do |order_installment|
      schedule.push({
        due_ymd: order_installment[:due_ymd],
        amount: order_installment[:amount],
      })
    end

    # scheduleにFeeオーダーinstallment情報を追加する
    fee_order_installments[:schedule].each do |order_installment|
      schedule_row = schedule.find{|row| row[:due_ymd] == order_installment[:due_ymd] }

      # 既存の日付の返済があれば金額を合計する
      if schedule_row.present?
        schedule_row[:amount] = (schedule_row[:amount] + order_installment[:amount]).round(2)
      else
      # ない場合は新しく追加
        schedule.push({
          due_ymd: order_installment[:due_ymd],
          amount: order_installment[:amount],
        })
      end
    end

    # 日付が順にならない可能性があるので念のためソートする
    schedule = schedule.sort_by{|row| row[:due_ymd]}

    # 合計値を足す
    total_amount =
      (new_order_installments[:total_amount] + fee_order_installments[:total_amount]).round(2)

    {
      count: schedule.count,
      schedule: schedule,
      total_amount: total_amount,
    }
  end
end
