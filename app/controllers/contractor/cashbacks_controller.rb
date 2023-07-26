# frozen_string_literal: true

class Contractor::CashbacksController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def cashback_info
    contractor = login_user.contractor

    cashback_histories = contractor.cashback_histories.ordered
    total_count        = cashback_histories.count
    cashback_histories = CashbackHistory.paginate(params['page'], cashback_histories, params['per_page'])

    render json: {
      success:                   true,
      cashback_for_next_payment: contractor.cashback_amount,
      cashback_use_ymd:          contractor.cashback_use_ymd,
      cashback_histories:        format_cachback_histories(cashback_histories),
      total_count:               total_count,
    }
  end

  private

  def format_cachback_histories(cashback_histories)
    cashback_histories.map do |cashback_history|
      {
        id:              cashback_history.id,
        exec_ymd:        cashback_history.exec_ymd,
        notes:           cashback_history.notes,
        point_type:      cashback_history.point_type,
        cashback_amount: cashback_history.cashback_amount.to_f,
      }
    end
  end
end