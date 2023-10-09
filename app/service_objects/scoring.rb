class Scoring
  def initialize(contractor_id)
    @contractor_id = contractor_id
  end

  def exec
    scoring_result = ScoringResult.new(
      contractor: contractor,
      scoring_class_setting: scoring_class_setting,
      limit_amount: limit_amount,
      class_type: class_type,
      financial_info_fiscal_year: financial_info_fiscal_year,

      years_in_business: years_in_business,
      years_in_business_score: years_in_business_score,
    )

    if financial_info_fiscal_year
      scoring_result.assign_attributes(
        register_capital: register_capital,
        shareholders_equity: shareholders_equity,
        total_revenue: total_revenue,
        net_revenue: net_revenue,
        current_ratio: current_ratio,
        de_ratio: de_ratio,

        register_capital_score: register_capital_score,
        shareholders_equity_score: shareholders_equity_score,
        total_revenue_score: total_revenue_score,
        net_revenue_score: net_revenue_score,
        current_ratio_score: current_ratio_score,
        de_ratio_score: de_ratio_score,

        total_score: total_score
      )
    end

    scoring_result.save!

    [nil, scoring_result]
  rescue Exception => e
    [e.message, nil]
  end

  private

  def contractor
    @contractor ||= Contractor.find(@contractor_id)
  end

  def limit_amount
    return @limit_amount if @limit_amount

    @limit_amount = case class_type
                    when 'a_class'
                      scoring_class_setting.class_a_limit_amount
                    when 'b_class'
                      scoring_class_setting.class_b_limit_amount
                    when 'c_class'
                      scoring_class_setting.class_c_limit_amount
                    when 'pending_class'
                      0
                    when 'reject_class'
                      0
                    end
  end

  def class_type
    return @class_type if @class_type

    return @class_type = 'reject_class' unless financial_info_fiscal_year

    # NGが2個以上
    return @class_type = 'reject_class' if ng_count >= 2

    # NGが1個以上
    if ng_count == 1
      if total_score >= scoring_class_setting.class_c_min
        return @class_type = 'pending_class'
      else
        return @class_type = 'reject_class'
      end
    end

    # NGが0個
    return @class_type = 'a_class' if total_score >= scoring_class_setting.class_a_min
    return @class_type = 'b_class' if total_score >= scoring_class_setting.class_b_min
    @class_type = 'c_class'
  end

  def total_score
    return @total_score if @total_score

    @total_score = 0
    @total_score += years_in_business_score if years_in_business_score > 0
    @total_score += register_capital_score if register_capital_score > 0
    @total_score += shareholders_equity_score if shareholders_equity_score > 0
    @total_score += total_revenue_score if total_revenue_score > 0
    @total_score += net_revenue_score if net_revenue_score > 0
    @total_score += current_ratio_score if current_ratio_score > 0
    @total_score += de_ratio_score if de_ratio_score > 0

    @total_score
  end

  def ng_count
    return @ng_count if @ng_count

    @ng_count = 0
    @ng_count += 1 if years_in_business_score == NG
    @ng_count += 1 if register_capital_score == NG
    @ng_count += 1 if shareholders_equity_score == NG
    @ng_count += 1 if total_revenue_score == NG
    @ng_count += 1 if net_revenue_score == NG
    @ng_count += 1 if current_ratio_score == NG
    @ng_count += 1 if de_ratio_score == NG

    @ng_count
  end

  # 各評価項目の値
  # No submit or No establishの場合はnil

  def years_in_business
    return @years_in_business if @years_in_business

    # "16/06/2560"
    reg_date = creden_api_data['REG_DATE']

    # 年がない場合はエラー
    raise 'no_establish_year' unless reg_date.present?

    establish_th_year = reg_date.split('/').last.to_i

    @years_in_business = convert_to_th_year(today.year) - establish_th_year
  end

  def register_capital
    @register_capital ||= creden_api_data['CAP_AMT']
  end

  def shareholders_equity
    @shareholders_equity ||= financial_info['BAL_BS23']
  end

  def total_revenue
    @total_revenue ||= financial_info['BAL_IN09']
  end

  def net_revenue
    @net_revenue ||= financial_info['BAL_IN21']
  end

  def current_ratio
    return nil if !financial_info['BAL_BS03'] || !financial_info['BAL_BS15']

    @current_ratio ||= financial_info['BAL_BS03'].to_f / financial_info['BAL_BS15']
  end

  def de_ratio
    return nil if !financial_info['BAL_BS22'] || !shareholders_equity

    @de_ratio ||= financial_info['BAL_BS22'].to_f / shareholders_equity
  end

  # 各評価項目に対するスコア

  NO_VALUE = nil # No submit or No establish
  MIN = -1
  NG = -1

  def years_in_business_score
    @years_in_business_score ||= calc_with_range_scores(years_in_business, [
      [10, 5],
      [5, 4],
      [3, 3],
      [1, 2],
      [MIN, 1]
    ])
  end

  def register_capital_score
    @register_capital_score ||= calc_with_range_scores(register_capital, [
      [5_000_000, 5],
      [2_000_000, 4],
      [1_000_000, 3],
      [500_000, 2],
      [MIN, 1]
    ])
  end

  def shareholders_equity_score
    @shareholders_equity_score ||= calc_with_range_scores(shareholders_equity, [
      [NO_VALUE, NG],
      [0, 0],
      [MIN, NG]
    ])
  end

  def total_revenue_score
    @total_revenue_score ||= calc_with_range_scores(total_revenue, [
      [NO_VALUE, NG],
      [10_000_000, 5],
      [5_000_000, 4],
      [1_000_000, 3],
      [300_000, 2],
      [100_000, 1],
      [MIN, NG]
    ])
  end

  def net_revenue_score
    @net_revenue_score ||= calc_with_range_scores(net_revenue, [
      [NO_VALUE, NG],
      [5_000_000, 5],
      [1_000_000, 4],
      [500_000, 3],
      [100_000, 2],
      [10_000, 1],
      [MIN, NG]
    ])
  end

  def current_ratio_score
    @current_ratio_score ||= calc_with_range_scores(current_ratio, [
      [1, 5],
      [0.7, 4],
      [0.5, 3],
      [0.4, 2],
      [0.3, 1],
      [MIN, NG]
    ])
  end

  def de_ratio_score
    @de_ratio_score ||= calc_with_range_scores(de_ratio, [
      [10, -1],
      [7.5, 1],
      [5.0, 2],
      [2.5, 3],
      [1.0, 4],
      [MIN, 5]
    ])
  end

  def calc_with_range_scores(value, range_scores)
    range_scores.each do |range_score|
      min = range_score[0]
      score = range_score[1]

      if min == NO_VALUE
        return score unless value
        next
      end

      return score if min == MIN || value >= min
    end
  end

  # 有効な年度の情報がなければnil
  def financial_info_fiscal_year
    @financial_info_fiscal_year ||= financial_info['FISCAL_YEAR'] ? financial_info['FISCAL_YEAR'].to_i : nil
  end

  def financial_info
    return @financial_info if @financial_info

    financial_info_list = creden_api_data['financialInfo']
    raise 'no_financial_info' if !financial_info_list.instance_of?(Array) || financial_info_list.empty?

    # ใช้ปีล่าสุดในรายการ
    @financial_info = financial_info_list.sort_by{ |info| info['FISCAL_YEAR'].to_i }.reverse.first

    # 最新年度のものが昨昨年度よりも古かったら無効
    return @financial_info = {} if @financial_info['FISCAL_YEAR'].to_i < current_fiscal_th_year - 2

    # 'null'をnilに変換
    @financial_info.each do |k, v|
      @financial_info[k] = nil if v == 'null'
    end

    @financial_info
  end

  def creden_api_data
    @creden_api_data ||= creden_api_result['data']
  end

  def creden_api_result
    return @creden_api_result if @creden_api_result

    res = CredenGetDataDetail.new(contractor.tax_id).exec

    raise 'creden_api_error' unless res['success']

    @creden_api_result = res
  end

  # 現年度(仏暦)
  def current_fiscal_th_year
    @current_fiscal_th_year ||= convert_to_th_year(today.month < 9 ? today.year : today.year + 1)
  end

  def today
    @today ||= Date.today
  end

  def scoring_class_setting
    @scoring_class_setting ||= ScoringClassSetting.latest
  end

  def convert_to_th_year(year)
    year + 543
  end
end
