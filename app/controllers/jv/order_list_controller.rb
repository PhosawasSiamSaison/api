# frozen_string_literal: true

class Jv::OrderListController < ApplicationController
  include CsvModule

  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    orders, total_count = Order.search(params)

    render json: {
      success: true,
      orders: format_orders(orders),
      total_count: total_count
    }
  end

  def order_detail
    order = Order.find(params[:order_id])

    render json: {
      success: true,
      order: format_jv_order_detail(order)
    }
  end

  def download_csv
    orders, _ = Order.search(params)
    send_order_list_csv(orders)
  end

  def cancel_order
    result = CancelOrder.new(params[:order_id], login_user).call

    render json: result
  end

  private
  def format_orders(orders)
    orders.preload(:dealer, :second_dealer, :contractor, :site).map do |order|
      {
        id: order.id,
        order_number: order.order_number,
        rescheduled_new_order_number: order.rescheduled_new_order&.order_number,
        site_code: order.any_site&.site_code,
        dealer: {
          id:          order.dealer&.id,
          dealer_code: order.dealer&.dealer_code,
          dealer_name: order.dealer&.dealer_name,
          dealer_type: order.dealer&.dealer_type_label || Dealer.new.dealer_type_label
        },
        contractor: {
          id: order.contractor.id,
          tax_id: order.contractor.tax_id,
          th_company_name: order.contractor.th_company_name,
          en_company_name: order.contractor.en_company_name,
          contractor_type: order.contractor.contractor_type_label[:label],
        },
        purchase_ymd: order.purchase_ymd,
        purchase_amount: order.purchase_amount.to_f,
        input_ymd: order.input_ymd,
        paid_up_ymd: order.paid_up_ymd,
        canceled_at: order.canceled_at,
        rescheduled_at: order.rescheduled_new_order&.rescheduled_at,
        is_applying_change_product: order.is_applying_change_product,
        is_product_changed: order.product_changed?,
        is_fee_order: order.fee_order,
        belongs_to_second_dealer: order.second_dealer.present?,
        belongs_to_project_finance: order.belongs_to_project_finance?,
        created_at: order.created_at.strftime('%Y-%m-%d %H:%M')
      }
      #
      # 一覧に項目を追加したら CSVにも追加するか確認する
      #
    end
  end
end
