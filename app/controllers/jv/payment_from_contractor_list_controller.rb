# frozen_string_literal: true

# Repayment List(to Be Confirmed Today)
class Jv::PaymentFromContractorListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    payments, total_count = SearchTodayRepaymentList.new(params).call

    render json: {
      success: true,
      payments: format_payments(payments),
      total_count: total_count
    }
  end

  def repayment_status_list
    render json: { success: true, list: repayment_status_items }
  end

  # Switch Sub Dealerの確認用ダイアログの情報
  def switch_sub_dealer_information
    information = SwitchSubDealer.new.get_information

    render json: {
      success: true,
      prev_due_ymd: information[:prev_due_ymd],
      next_due_ymd: information[:next_due_ymd],
      orders: information[:orders],
    }
  end

  # SubDealerの対象のオーダーを一括Switchする
  def switch_sub_dealer
    orders = params[:orders]
    SwitchSubDealer.new.exec_switch(orders, login_user)

    render json: { success: true }
  end

  private
  # セレクトボックスのアイテム
  def repayment_status_items
    ['all', 'over_due', 'upcoming_due', 'not_due_yet'].map do |status_code|
      {
        code: status_code,
        label: I18n.t("select_item.repayment_list.repayment_status.#{status_code}")
      }
    end
  end

  # paymentからステータス表示セットを取得
  def repayment_status_label(payment)
    code =
      if payment.over_due?
        'over_due'
      elsif payment.next_due?
        'upcoming_due'
      elsif payment.all_orders_input_ymd_present? # 全てのInput Dateが入力済
        'not_due_yet'
      elsif payment.any_orders_input_ymd_blank? # 一部 Input Date未入力あり
        'not_input_yet'
      else
        raise 'undefind status'
      end

    {
      code: code,
      label: I18n.t("select_item.repayment_list.repayment_status.#{code}")
    }
  end

  def format_payments(payments)
    payments.map do |payment|
      contractor = payment.contractor

      {
        id: payment.id,
        contractor: {
          id: contractor.id,
          tax_id: contractor.tax_id,
          th_company_name: contractor.th_company_name,
          en_company_name: contractor.en_company_name,
          exceeded_amount: contractor.exceeded_amount
        },
        due_ymd: payment.due_ymd,
        amount: payment.calc_total_amount_include_not_input_date,
        repayment_status: repayment_status_label(payment),
        evidence_uploaded_at: contractor.evidence_uploaded_at
      }
    end
  end
end
