# frozen_string_literal: true

class Jv::ContractorUserDetailController < ApplicationController
  include CsvModule

  before_action :auth_user

  def download_csv
    contractor_user = ContractorUser.find(params[:contractor_user_id])

    send_contractor_user_detail_csv(contractor_user)
  end
end
