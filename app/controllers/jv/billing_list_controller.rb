# frozen_string_literal: true

class Jv::BillingListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    contractor_billing_data_list, total_count = ContractorBillingData.search(params)

    formatted_billing_list = contractor_billing_data_list.map do |contractor_billing_data|
      contractor = contractor_billing_data.contractor

      {
        id:              contractor_billing_data.id,
        due_ymd:         contractor_billing_data.due_ymd,
        tax_id:          contractor.tax_id,
        th_company_name: contractor.th_company_name,
        en_company_name: contractor.en_company_name,
        amount:          contractor_billing_data.due_amount.to_f,
      }
    end

    render json: {
      success: true,
      billing_list: formatted_billing_list,
      total_count: total_count,
    }
  end

  def daily_zip_list
    daily_zip_list = ContractorBillingZipYmd.order(due_ymd: :desc).map do |contractor_billing_zip_ymd|
      {
        id: contractor_billing_zip_ymd.id,
        due_ymd: contractor_billing_zip_ymd.due_ymd,
      }
    end

    render json: {
      success: true,
      daily_zip_list: daily_zip_list
    }
  end

  def download_pdf
    contractor_billing_data = ContractorBillingData.find(params[:id])

    pdf, file_name = GenerateContractorBillingPDF.new.call(contractor_billing_data)

    send_data(
      pdf.render,
      type: 'application/pdf',
      filename: file_name,
    )
  end

  def download_zip
    billing_zip_ymd = ContractorBillingZipYmd.find(params[:id])
    due_ymd = billing_zip_ymd.due_ymd

    send_data(
      billing_zip_ymd.zip_file.download,
      type: 'application/zip',
      filename: "contractor-billing_#{due_ymd}.zip"
    )
  end
end
