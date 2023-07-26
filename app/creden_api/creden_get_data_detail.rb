class CredenGetDataDetail < CredenApiBase
  def initialize(tax_id)
    @tax_id = tax_id
  end

  def exec
    path = switch_path(:get_data_detail)

    params = { 'id' => @tax_id }

    begin
      # リクエスト
      use_mock =
        JvService::Application.config.try(:creden_use_mock) ||
        JvService::Application.config.try(:creden_host).blank?

      res = use_mock ? mock_response(@tax_id) : request(path, params)
    rescue Exception => e
      log_error('Get Data Detail', e)

      res = { 'success' => false }
    end

    res
  end

  private

  def request(path, params)
    log_start('Get Data Detail', creden_host + path, params)

    res =
      creden_connection.get do |req|
        req.url(path)
        req.headers['apikey'] = api_key
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end

    log_finish('Get Data Detail', res.body)

    JSON.parse(res.body)
  end

  def mock_response(tax_id)
    th_year = Time.zone.now.year + 543

    {
      "success" => true,
      "data" => {
        "JP_NO" => "0105560098166",                                              # TAX ID
        "JP_TYPE_TNAME" => "บริษัทจำกัด",                                           # Business Registration
        "CAP_AMT" => 1405000,                                                    # Registered capital
        "FULL_ADDRESS" => "9/22  ถนนราชพฤกษ์ แขวงบางระมาด เขตตลิ่งชัน กรุงเทพมหานคร", # Full Address
        "JP_TNAME" => "ครีเดน เอเชีย จำกัด",                                        # Juristic person
        "REG_DATE" => "16/06/#{th_year - 5}",                                    # Registration Date
        "PARTNER_MANAGER" => "นายภาวุธ พงษ์วิทยภานุ ลงลายมือชื่อ/n",                    # Director / Authorized director
        "PHONE_NO" => "-",                                                       # Phone No
        "STATUS_TNAME" => "ยังดำเนินกิจการอยู่",                                      # Corporate status
        "JP_ENAME" => "CREDEN ASIA COMPANY LIMITED",                             # Juristic person in English

        "financialInfo" => [
          {
            "BAL_IN01_10" => "null",   # Realized gain (loss)
            "BAL_BS15" => 460249.92,   # Current liabilities
            "BAL_BS02" => "null",      # Inventory
            "BAL_BS99" => 11502891.49, # Total Liabilities and Equity
            "BAL_BS10" => 94613.09,    # Property, plant and equipment
            "BAL_BS36" => "null",      # Non-current liabilities
            "BAL_IN09" => 5201368.77,  # Total Revenue
            "BAL_IN10" => 679452,      # Cost of sales
            "BAL_BS19" => 94613.09,    # Income tax
            "BAL_IN20" => 9353317.15,  # Total expenditure
            "BAL_BS22" => 460249.92,   # Total Liabilities
            "BAL_IN11" => 8662886.51,  # Distribution expense
            "FISCAL_YEAR" => th_year.to_s,   # Fiscal Year
            "BAL_BS23" => 11042641.57, # Shareholders Equity
            "BAL_IN21" => -4151948.38, # Net Revenue
            "BAL_BS03" => 11408278.4,  # Current asset
            "BAL_BS01" => 964470.57    # Account receivable
          },
          {
            "BAL_IN01_10" => "null",
            "BAL_BS15" => 129308.28,
            "BAL_BS02" => "null",
            "BAL_BS99" => 2323898.23,
            "BAL_BS10" => 182442.92,
            "BAL_BS36" => "null",
            "BAL_IN09" => 455535.49,
            "BAL_IN10" => "null",
            "BAL_BS19" => 182442.92,
            "BAL_IN20" => 5594720.02,
            "BAL_BS22" => 129308.28,
            "BAL_IN11" => 5594720.02,
            "FISCAL_YEAR" => (th_year - 1).to_s,
            "BAL_BS23" => 2194589.95,
            "BAL_IN21" => -5139184.53,
            "BAL_BS03" => 2141455.31,
            "BAL_BS01" => 2351.95
          },
          {
            "BAL_IN01_10" => "null",
            "BAL_BS15" => 42417.6,
            "BAL_BS02" => "null",
            "BAL_BS99" => 2376192.08,
            "BAL_BS10" => 12076.95,
            "BAL_BS36" => "null",
            "BAL_IN09" => 55461.88,
            "BAL_IN10" => "null",
            "BAL_BS19" => 12076.95,
            "BAL_IN20" => 4074412.35,
            "BAL_BS22" => 42417.6,
            "BAL_IN11" => 4074412.35,
            "FISCAL_YEAR" => (th_year - 2).to_s,
            "BAL_BS23" => 2333774.48,
            "BAL_IN21" => -4018950.47,
            "BAL_BS03" => 2364115.13,
            "BAL_BS01" => 8760
          },
          {
            "BAL_IN01_10" => "null",
            "BAL_BS15" => 84625,
            "BAL_BS02" => "null",
            "BAL_BS99" => 437349.95,
            "BAL_BS10" => "null",
            "BAL_BS36" => "null",
            "BAL_IN09" => 174.95,
            "BAL_IN10" => "null",
            "BAL_BS19" => "null",
            "BAL_IN20" => 397450,
            "BAL_BS22" => 84625,
            "BAL_IN11" => 397450,
            "FISCAL_YEAR" => (th_year - 3).to_s,
            "BAL_BS23" => 352724.95,
            "BAL_IN21" => -397275.05,
            "BAL_BS03" => 437349.95,
            "BAL_BS01" => "null"
          },
          {
            "BAL_IN01_10" => "null",
            "BAL_BS15" => "null",
            "BAL_BS02" => "null",
            "BAL_BS99" => "null",
            "BAL_BS10" => "null",
            "BAL_BS36" => "null",
            "BAL_IN09" => "null",
            "BAL_IN10" => "null",
            "BAL_BS19" => "null",
            "BAL_IN20" => "null",
            "BAL_BS22" => "null",
            "BAL_IN11" => "null",
            "FISCAL_YEAR" => (th_year - 4).to_s,
            "BAL_BS23" => "null",
            "BAL_IN21" => "null",
            "BAL_BS03" => "null",
            "BAL_BS01" => "null"
          },
          {
            "BAL_IN01_10" => "null",
            "BAL_BS15" => "null",
            "BAL_BS02" => "null",
            "BAL_BS99" => "null",
            "BAL_BS10" => "null",
            "BAL_BS36" => "null",
            "BAL_IN09" => "null",
            "BAL_IN10" => "null",
            "BAL_BS19" => "null",
            "BAL_IN20" => "null",
            "BAL_BS22" => "null",
            "BAL_IN11" => "null",
            "FISCAL_YEAR" => (th_year - 5).to_s,
            "BAL_BS23" => "null",
            "BAL_IN21" => "null",
            "BAL_BS03" => "null",
            "BAL_BS01" => "null"
          }
        ]
      }
    }
  end
end
