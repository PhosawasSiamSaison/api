# frozen_string_literal: true

class Dealer::HomeController < ApplicationController
  before_action :auth_user

  def graph1
    dealer = login_user.dealer

    # グラフ左
    credit_limit_amount = dealer.credit_limit_amount
    remaining_principal = dealer.remaining_principal
    available_balance =   dealer.available_balance

    # グラフ中央
    contractors = dealer.contractors.active
    contractor_count = contractors.count
    # 現在支払い中のコントラクター
    in_use_count = contractors.in_use_order_contractor.count
    # 一度も利用がないコントラクター
    not_use_count = contractor_count - contractors.has_order_contractor.count
    # 利用したことはあるが、現在は支払いがないコントラクター
    not_in_use_count = contractors.has_order_contractor.count - in_use_count

    # グラフ右
    # TODO リスケ分を除外するか確認
    orders = dealer.orders.exclude_canceled
    order_count = orders.count
    inputed_ymd_count = orders.inputed_ymd.count
    not_input_ymd_count = order_count - inputed_ymd_count

    render json: {
      success:           true,

      credit_limit:      credit_limit_amount,
      available_balance: available_balance,
      used_amount:       remaining_principal,

      contractor_count:  contractor_count,
      in_use_count:      in_use_count,
      not_in_use_count:  not_in_use_count,
      not_use_count:     not_use_count,

      order_count:       order_count,
      inputed_ymd_count: inputed_ymd_count,
      not_input_ymd_count: not_input_ymd_count,
    }
  end

  def graph2
    dealer = login_user.dealer

    purchase_data = format_graph2(dealer)

    render json: {
      success: true,
      purchase_data: purchase_data,
    }
  end

  private

  def format_graph2(dealer)
    # 直近の12件
    dealer_purchase_of_months = dealer.dealer_purchase_of_months.order(month: :DESC).limit(12)

    # 日付の昇順でソートする
    dealer_purchase_of_months.sort_by(&:month).map do |purchase_of_month|
      {
        month: purchase_of_month.month,
        purchase_amount: purchase_of_month.purchase_amount.to_f,
        order_count: purchase_of_month.order_count,
      }
    end
  end
end
