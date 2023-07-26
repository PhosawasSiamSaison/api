# frozen_string_literal: true

class Contractor::ItemListController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  # 購入商品の詳細(CBM系)
  def item_list
    order = find_order(params[:order_id])

    # RUDY から Items を取得
    rudy_items = RudySearchProduct.new(order).exec
    # Paging
    items, total_count = RudyApiBase.paging(rudy_items, params)

    render json: {
      success: true,
      order: {
        order_number: order.order_number,
        purchase_ymd: order.purchase_ymd,
        dealer:       {
          id:          order.dealer.id,
          dealer_code: order.dealer.dealer_code,
          dealer_name: order.dealer.dealer_name
        },
        items:        items,
        total_count:  total_count
      }
    }
  end

  # 購入商品の詳細(CPAC系と全てのProjectのオーダー)
  def detail_list
    order = find_order(params[:order_id])

    # RUDY から Items を取得
    rudy_items = RudySearchCpacProduct.new(order).exec
    # Paging
    items, total_count = RudyApiBase.paging(rudy_items, params)

    site = order.any_site

    render json: {
      success: true,
      order: {
        order_number: order.order_number,
        purchase_ymd: order.purchase_ymd,
        dealer:       {
          id:          order.dealer.id,
          dealer_code: order.dealer.dealer_code,
          dealer_name: order.dealer.dealer_name
        },
        site: {
          site_name: site.site_name,
          site_code: site.site_code,
          closed:    site.closed?
        },
        items:       items,
        total_count: total_count
      }
    }
  end

  private
  def find_order(order_id)
    # キャンセルとリスケ分は除外する
    login_user.contractor.orders.exclude_canceled.find(order_id)
  end
end
