# frozen_string_literal: true

class Jv::DealerListController < ApplicationController
  before_action :auth_user

  # Dealerの一覧を取得する。
  # 検索条件あり
  def search
    parse_search_params
    dealers = Dealer.search(params)

    paginated_dealers, total_count = [
      dealers.paginate(params[:page], dealers, params[:per_page]), dealers.count
    ]

    render json: {
      success:     true,
      dealers:     format_dealer_list(paginated_dealers),
      total_count: total_count
    }
  end

  private

  def format_dealer_list(dealers)
    dealers.map do |dealer|
      {
        id:          dealer.id,
        tax_id:      dealer.tax_id,
        dealer_type: dealer.dealer_type_label,
        dealer_code: dealer.dealer_code,
        dealer_name: dealer.dealer_name,
        en_dealer_name: dealer.en_dealer_name,
        status:      dealer.status_label,
        created_at:  dealer.created_at,
        updated_at:  dealer.updated_at,
        area:        {
          id:        dealer.area_id,
          area_name: dealer.area.area_name
        },
        update_user_name: dealer.update_user&.full_name
      }
    end
  end
end
