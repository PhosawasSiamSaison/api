# frozen_string_literal: true

class Jv::PaymentForDealerListController < ApplicationController
  before_action :auth_user

  def search
    input_ymd = params[:input_ymd]
    dealer_id = params[:dealer_id]

    # 対象のオーダーを持っているDealerIDを取得
    dealer_ids = Order.payment_target_orders(input_ymd)
      .pluck(:dealer_id, :second_dealer_id).flatten.compact.uniq

    # Dealer指定の検索条件
    if dealer_id.present?
      # ページングの為に配列形式で取得する
      dealers = dealer_ids.include?(dealer_id.to_i) ? Dealer.where(id: dealer_id) : Dealer.none
    else
      dealers = Dealer.where(id: dealer_ids).order(:created_at)
    end

    target_dealers, total_count = dealers.paging(params)

    # Dealer Listをフォーマットする
    formatted_dealers = target_dealers.map do |dealer|
      # 対象のオーダーを絞る
      target_orders = dealer.gen_payment_target_orders(input_ymd)

      {
        dealer_id:    dealer.id,
        dealer_name:  dealer.dealer_name,
        dealer_type:  dealer.dealer_type_label,
        order_count:  target_orders.count,
        total_amount: dealer.dealer_payment_total_amount(target_orders),
      }
    end

    render json: {
      success: true,
      dealers: formatted_dealers,
      total_count: total_count,
    }
  end

  # エクセルファイルもしくは複数エクセルをZIPにまとめたファイルを返す
  def download_excel
    dealer = Dealer.find(params[:dealer_id])
    input_ymd = params[:input_ymd]

    file_data, type, file_name = DealerPaymentFileCreator.new.call(dealer, input_ymd)

    send_data(file_data, type: type, filename: file_name)
  end

  private
  def filename_date
    Time.zone.now.strftime('%Y%m%d-%H%M')
  end
end
