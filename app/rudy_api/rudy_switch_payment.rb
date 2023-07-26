class RudySwitchPayment < RudyApiBase
  def initialize(order)
    @order = order
  end

  def exec
    begin
      # 再約定したオーダーでは呼ばない(呼ばれない想定)
      return if @order.rescheduled_new_order?

      # リクエスト
      res = (use_test_params? || Rails.env.production?) ? request : mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]
    rescue Exception => e
      log_error('Switch Payment', e)

      raise e
    end
  end

  private

  def request
    product = @order.product
    dealer_interest_rate = @order.dealer.interest_rate
    amount = @order.purchase_amount

    url = switch_url(:switch_payment)

    params = {
      "dealer_code"            => @order.dealer.dealer_code,
      "tax_id"                 => @order.contractor.tax_id,
      "DocID"                  => @order.order_number,
      "amount"                 => @order.total_amount,
      "product_id"             => product.product_key,
      "product_name"           => product.product_name,
      "number_of_installments" => product.number_of_installments,
      "annual_interest_rate"   => (dealer_interest_rate || product.annual_interest_rate).to_f,
      "monthly_interest_rate"  => product.monthly_interest_rate.to_f,
      "total_amount"           => product.total_amount(amount, dealer_interest_rate),
      "installment_amount"     => product.installment_amount(amount, dealer_interest_rate),
      "installment_amounts"    => product.rudy_install_amounts(amount, dealer_interest_rate),
    }

    bearer = RudyApiSetting.bearer

    log_start('Switch Payment', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Switch Payment', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    {
      "status" => 200,
      "items" => "Success"
    }
  end
end
