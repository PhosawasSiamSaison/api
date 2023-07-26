class RudyCreditScoring < RudyApiBase
  def initialize(tax_id)
    @tax_id = tax_id
  end

  def exec
    begin
      result = nil
      error = nil

      # リクエスト
      # TODO RUDYのAPI修正後に以下を修正する
      # res = (use_test_params? || Rails.env.production?) ? request : mock_response
      res = mock_response

      # レスポンスのエラーチェック
      raise res.to_json if res["status"] != RES_STATUS[:SUCCESS]

      result = res["items"].deep_symbolize_keys
    rescue Exception => e
      log_error('Credit Scoring', e)

      # エラー時はエラーの配列を返却
      error = res["items"]
    end

    [result, error]
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
          "DocID" => "1509900404312"
        }
      elsif Rails.env.production?
        {
          "DocID" => @tax_id
        }
      end

    bearer = RudyApiSetting.bearer

    log_start('Credit Scoring', rudy_host + url, params, bearer)

    res =
      rudy_connection.post do |req|
        req.url(url)
        req.headers['Authorization'] = "Bearer #{bearer}"
        req.body = params
      end

    log_finish('Credit Scoring', res.body)

    JSON.parse(res.body)
  end

  def mock_response
    res = {
      "status" => 200,
      "items" => {
        "dealers" => [],
        "average" => {
            "credit_term" => "30.5",
            "credit_limit" => "5555.55",
            "score_infomation" => {
                "class" => "S",
                "score" => "85.4",
                "no_of_on_hand" => "5.2",
                "valuer_and_type" => "30.0",
                "contract_per_site" => "35.8",
                "no_of_work_be_on_time" => "15.7"
            }
        }
      }
    }

    if Dealer.count > 0
      res["items"]["dealers"].push({
          "dealer_code" => Dealer.first.dealer_code,
          "credit_term" => "30",
          "credit_limit" => "6000.00",
          "transactions" => [
            {
              "months" => []
            }
          ],
          "projects" => [
            {
              "score" => "S",
              "project_name" => "บ้านสวยในซอย",
              "project_value" => "5.00",
              "project_type" => "บ้านเดี่ยว",
              "project_progress" => "10"
            }
          ],
          "score_infomation" => {
            "class" => "S",
            "score" => "85",
            "no_of_on_hand" => "5",
            "valuer_and_type" => "30",
            "contract_per_site" => "35",
            "no_of_work_be_on_time" => "15"
          }
        })
    end

    if Dealer.count > 1
      res["items"]["dealers"].push({
        "dealer_code" => Dealer.second.dealer_code,
        "credit_term" => "31",
        "credit_limit" => "5000.00",
        "transactions" => [
          {
            "year" => "2018",
            "peak_amount" => "1000.00",
            "avg_per_month_amount" => "100.00",
            "avg_overdue" => "10.00",
            "months" => [
              {
                "month" => "03",
                "sum_amount_monthly" => "285877.08"
              }
            ]
          },
          {
            "year" => "2019",
            "peak_amount" => "1100.00",
            "avg_per_month_amount" => "110.00",
            "avg_overdue" => "11.00",
            "months" => [
              {
                "month" => "03",
                "sum_amount_monthly" => "285877.08"
              }
            ]
          }
        ],
        "projects" => [
          {
            "score" => "S",
            "project_name" => "บ้านสวยในซอย",
            "project_value" => "5.00",
            "project_type" => "บ้านเดี่ยว",
            "project_progress" => "10"
          },
          {
            "score" => "S",
            "project_name" => "บ้านสวย",
            "project_value" => "1.50",
            "project_type" => "บ้านเดี่ยว",
            "project_progress" => "10"
          }
        ],
        "score_infomation" => {
          "class" => "S",
          "score" => "85",
          "no_of_on_hand" => "5",
          "valuer_and_type" => "30",
          "contract_per_site" => "35",
          "no_of_work_be_on_time" => "15"
        }
      })
    end

    res
  end
end
