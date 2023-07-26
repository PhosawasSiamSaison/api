class RudySearchCpacProduct < RudyApiBase
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
          product_no:   item["product_no"],
          product_name: item["product_name"],
          billing_no:   item["DocID"],
          billing_ymd:  format_date(item["doc_date"]),
          year:         item["year"],
          month:        item["month"],
          qty:          format_amount(item["quantity"]),
          cubic:        item["unit"],
          price:        format_amount(item["price"]),
          amount:       format_amount(item["net_amount"]),
          quotation_doc_urls: item["quotation_document_urls"] || [],
          invoice_doc_urls:   item["invoiced_document_urls"] || [],
        }
      end
    rescue Exception => e
      log_error('Search CPAC Product', e)

      # エラー時は空の配列を返す
      []
    end
  end

  private
  def format_amount(amount)
    amount.to_s.delete(',').to_f
  end

  def format_date(doc_date)
    Time.parse(doc_date).strftime("%Y%m%d")
  end

  def request
    url = switch_url(:search_cpac_product)

    # 開発時はRUDYサーバにマッチできるデータがないのでテスト用のパラメーターを使用する
    params =
      if use_test_params?
        {
          "DocID" => "RD202001070002",
          "dealer_code" => "12342"
        }
      elsif Rails.env.production?
        {
          "DocID" => @order.order_number,
          "dealer_code" => @order.dealer.dealer_code
        }
      end

    bearer = RudyApiSetting.bearer

    log_start('Search CPAC Product', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Search CPAC Product', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    {
      "status" => 200,
      "items" => [
        {
          "product_no" => "ZAA700070949",
          "product_name" => "สกรูยึดกระเบื้องลอนคู่แปเหล็ก 4.8x90mm.",
          "DocID" => "RD202001070002",
          "doc_date" => "2020-01-30 14:41:45",
          "year" => "2020",
          "month" => "01",
          "quantity" => "1.000",
          "unit" => "แพ็ค\n",
          "price" => "1.00",
          "net_amount" => "1.00",
          "quotation_document_urls" => [
            "http://localhost:3000/robots.txt",
            "http://localhost:3000/robots.txt",
          ],
          "invoiced_document_urls": nil
        },
        {
          "product_no" => "ZAA700060117",
          "product_name" => "เหล็กปลอก 10x15x5.5mm ตรามือ",
          "DocID" => "RD202001070002",
          "doc_date" => "2020-01-30 14:41:45",
          "year" => "2020",
          "month" => "01",
          "quantity" => "3.000",
          "unit" => "กก.",
          "price" => "5.00",
          "net_amount" => "15.00"
        }
      ]
    }
  end
end
