# frozen_string_literal: true

class SearchRepaymentList
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def call
    relation = Payment.eager_load(:contractor).order(:due_ymd)

    # tax id
    if params.dig(:search, :tax_id).present?
      tax_id   = params.dig(:search, :tax_id)
      # HACK 同じ検索条件が複数あるので纏める
      relation = relation.where("contractors.tax_id LIKE ?", "#{tax_id}%")
    end

    # Company Name
    if params.dig(:search, :company_name).present?
      company_name = params.dig(:search, :company_name)
      # HACK 同じ検索条件が複数あるので纏める
      relation     = relation.where("CONCAT(en_company_name, th_company_name) LIKE ?", "%#{company_name}%")
    end

    # Due Date
    if params.dig(:search, :due_date).present?
      purchase = params.dig(:search, :due_date)
      from_ymd = purchase[:from_ymd].presence || "00000101"
      to_ymd   = purchase[:to_ymd].presence || "99991231"

      relation = relation.where(due_ymd: from_ymd..to_ymd)
    end

    # Status
    status = params.dig(:search, :status)
    if status.present? && %w(next_due not_due_yet).include?(status)
      case params.dig(:search, :status).to_sym
      when :next_due
        relation = relation.next_due
      when :not_due_yet
        relation = relation.not_due_yet
      end
    else
      relation = relation.where(status: %w(next_due not_due_yet))
    end

    # Paging
    if params[:page].present? && params[:per_page].present?
      result = relation.page(params[:page]).per(params[:per_page])
    else
      result = relation
    end

    [result, relation.count]
  end
end
