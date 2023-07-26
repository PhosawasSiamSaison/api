# frozen_string_literal: true

class Jv::DailyReceivedAmountHistoryController < ApplicationController
  include CsvModule

  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    receive_amount_histories, total_amount, total_count = ReceiveAmountHistory.search(params)

    render json: {
      success: true,
      histories: format_receive_amount_histories(receive_amount_histories),
      total_amount: total_amount,
      total_count: total_count
    }
  end

  def download_csv
    receive_amount_histories, _, _ = ReceiveAmountHistory.search(params)
    send_daily_received_amount_history_csv(receive_amount_histories)
  end

  private
  def format_receive_amount_histories(receive_amount_histories)
    receive_amount_histories.map do |history|
      contractor  = history.contractor
      create_user = history.create_user

      {
        id: history.id,
        contractor: {
          id: contractor.id,
          tax_id: contractor.tax_id,
          th_company_name: contractor.th_company_name,
          en_company_name: contractor.en_company_name
        },
        receive_ymd: history.receive_ymd,
        receive_amount: history.receive_amount.to_f,
        comment: history.comment,
        operated_at: history.created_at,
        operated_user: {
          id: create_user&.id,
          full_name: create_user&.full_name
        }
      }
    end
  end
end
