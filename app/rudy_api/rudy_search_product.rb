class RudySearchProduct < RudyApiBase
  def initialize(order)
    @order = order
  end

  def exec
    begin
      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]

      res["items"].map do |item|
        {
          item_name:       item["product_name"],
          item_quantity:   format_amount(item["qty"]),
          item_unit_price: format_amount(item["price"]),
          item_net_amount: format_amount(item["net_amount"]),
        }
      end
    rescue Exception => e
      log_error('Search Product', e)

      # エラー時は空の配列を返す
      []
    end
  end

  private
  def format_amount(amount)
    amount.to_s.delete(',').to_f
  end

  def request
    url = switch_url(:search_product)

    # 開発時はRUDYサーバにマッチできるデータがないのでテスト用のパラメーターを使用する
    params =
      if use_test_params?
        {
          "DocID" => "RD201812190001",
          "dealer_code" => "3015696"
        }
      elsif Rails.env.production?
        {
          "DocID" => @order.order_number,
          "dealer_code" => @order.dealer.dealer_code
        }
      end

    bearer = RudyApiSetting.bearer

    log_start('Search Product', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Search Product', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    {
      "status" => 200,
      "items" => [
        {
          "product_name" => "sample 1",
          "price" => "1,000.0",
          "qty" => "1.00",
          "unit" => "",
          "net_amount" => "1000"
        },
        {
          "product_name" => "sample 2",
          "price" => 1000.0,
          "qty" => 2.0,
          "unit" => "",
          "net_amount" => 2000
        },
        {
          "product_name" => "sample 3",
          "price" => "1.0",
          "qty" => "3,000.00",
          "unit" => "",
          "net_amount" => "3,000"
        }
      ]
    }
  end
end
