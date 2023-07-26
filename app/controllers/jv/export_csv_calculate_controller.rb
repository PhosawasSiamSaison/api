# frozen_string_literal: true
class Jv::ExportCsvCalculateController < ApplicationController
  include CsvModule
  include AvailableSettingsFormatterModule

  before_action :auth_user

  def download_available_settings_detail_csv
    contractor = Contractor.find(params[:contractor_id])
    available_settings = format_available_settings(contractor, detail_view: true)

    send_available_settings_detail_csv(available_settings)
  end

  def download_calculate_payment_and_installment
    payment = Payment.find_by(id: params[:payment_id])

    send_calculate_payment_and_installment(payment)
  end
end
