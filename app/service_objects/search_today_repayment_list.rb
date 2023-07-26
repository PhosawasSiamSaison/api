# frozen_string_literal: true

class SearchTodayRepaymentList
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def call
    # InputDateなしも含める
    payments = Payment.eager_load(:contractor).order(:due_ymd)

    payments =
      case params.dig(:search, :repayment_status)
      when 'over_due'
        over_due_repayments(payments)
      when 'upcoming_due'
        upcoming_due_repayments(payments)
      when 'not_due_yet'
        not_due_yet_repayments(payments)
      else # all or else
        over_due_repayments(payments) +
        upcoming_due_repayments(payments) +
        not_due_yet_repayments(payments)
      end

    # ページング前の合計
    total_count = payments.count

    # Paging
    if params[:page].present? && params[:per_page].present?
      payments = Kaminari.paginate_array(payments).page(params[:page]).per(params[:per_page])
    end

    [payments, total_count]
  end

  private
  def over_due_repayments(payments)
    search_repayment(payments.over_due)
  end

  def upcoming_due_repayments(payments)
    next_due_on_today(payments) +
    next_due_exist_evidence(payments) +
    next_due_exist_exceeded(payments)
  end

  def not_due_yet_repayments(payments)
    not_due_yet_exist_evidence(payments) +
    not_due_yet_exist_exceeded(payments)
  end


  # 今日期限で未完了
  def next_due_on_today(payments)
    repayments = payments.next_due.where(due_ymd: BusinessDay.today_ymd)

    search_repayment(repayments)
  end

  # 入金処理待ちのpayment
  def next_due_exist_evidence(payments)
    repayments = payments.eager_load(:contractor)
      .next_due
      .where.not(due_ymd: BusinessDay.today_ymd)
      .where(contractors: { check_payment: true })

    search_repayment(repayments)
  end

  # ExceededがあるContractorのPayment
  def next_due_exist_exceeded(payments)
    repayments = payments.eager_load(:contractor)
      .next_due
      .where.not(due_ymd: BusinessDay.today_ymd)
      .where(contractors: { check_payment: false })
      .where("contractors.pool_amount > 0")

    search_repayment(repayments)
  end

  # NotDueYetでエビデンス未チェック
  def not_due_yet_exist_evidence(payments)
    repayments = payments.eager_load(:contractor)
      .not_due_yet
      .where(contractors: { check_payment: true })

    search_repayment(repayments)
  end

  # NotDueYetでExceededあり
  def not_due_yet_exist_exceeded(payments)
    repayments = payments.eager_load(:contractor)
      .not_due_yet
      .where(contractors: { check_payment: false })
      .where("contractors.pool_amount > 0")

    search_repayment(repayments)
  end

  def search_repayment(payments)
    return [] if payments.blank?

    # TAX ID(tax_id)
    if params.dig(:search, :tax_id).present?
      tax_id   = params.dig(:search, :tax_id)
      payments = payments.where("contractors.tax_id LIKE ?", "#{tax_id}%")
    end

    # Company Name
    if params.dig(:search, :company_name).present?
      company_name = params.dig(:search, :company_name)
      payments     = payments.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
    end

    payments
  end
end
