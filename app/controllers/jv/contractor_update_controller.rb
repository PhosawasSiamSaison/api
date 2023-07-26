# frozen_string_literal: true

class Jv::ContractorUpdateController < ApplicationController
  include AvailableSettingsFormatterModule, FileHelperModule

  before_action :auth_user

  def contractor
    contractor = Contractor.find(params[:contractor_id])

    view_formatter = ViewFormatter::ContractorFormatter.new(contractor)
    formatted_contractor = view_formatter.format_update_with_hash(
      {
        status: contractor.status_label,
      }
    )

    applied_dealers = contractor.applied_dealers.map{|applied_dealer|
      {
        dealer_id:  applied_dealer.dealer_id,
        dealer_name: applied_dealer.dealer.dealer_name,
        dealer_type: applied_dealer.dealer.dealer_type_label,
        applied_ymd: applied_dealer.applied_ymd,
      }
    }

    # 添付された申込書類のファイル名とURL
    attached_documents = {
      # Company情報
      company_certificate: file_link(contractor.doc_company_certificate),
      vat_certification:   file_link(contractor.doc_vat_certification),
      office_store_map:    file_link(contractor.doc_office_store_map),
      financial_statement: file_link(contractor.doc_financial_statement),
      application_form:    file_link(contractor.doc_application_form),
      copy_of_national_id: file_link(contractor.doc_copy_of_national_id),

      # Owner情報
      selfie_image: file_link(contractor.selfie_image),
      card_image:   file_link(contractor.national_card_image),
    }

    render json: {
      success: true,
      contractor: formatted_contractor,
      applied_dealers: applied_dealers,
      attached_documents: attached_documents,
    }
  end

  def update_contractor
    contractor = Contractor.find(params[:contractor_id])
    contractor.attributes  = update_contractor_params
    contractor.update_user = login_user

    contractor.main_dealer_id = params[:applied_dealers].present? ? params[:applied_dealers].first[:dealer_id] : nil

    SetSameContractorUser.new(params, contractor).call

    errors = []
    ActiveRecord::Base.transaction do
      if contractor.save
        # Applied Dealerの作成
        contractor.update_applied_dealers(params[:applied_dealers])

        # 申し込み書類のアタッチ
        contractor.attach_documents(params[:contractor][:application_documents])
      else
        errors = contractor.error_messages
      end
    end

    if errors.blank?
      render json: { success: true }
    else
      render json: { success: false, errors: errors }
    end
  end

  private
  def update_contractor_params
    params.require(:contractor).permit(
      :doc_company_registration,
      :doc_vat_registration,
      :doc_owner_id_card,
      :doc_authorized_user_id_card,

      :doc_bank_statement,
      :doc_tax_report,

      :contractor_type,
      :use_only_credit_limit,
      :stop_payment_sms,
      :is_switch_unavailable,
      :enable_rudy_confirm_payment,

      :th_company_name,
      :en_company_name,
      :address,
      :phone_number,
      :registration_no,
      :tax_id,
      :establish_year,
      :establish_month,
      :capital_fund_mil,
      :employee_count,
      :status,

      :shareholders_equity,
      :recent_revenue,
      :short_term_loan,
      :long_term_loan,
      :recent_profit,

      :th_owner_name,
      :en_owner_name,
      :owner_address,
      :owner_birth_ymd,
      :owner_mobile_number,
      :owner_personal_id,
      :owner_sex,
      :owner_email,
      :owner_line_id,

      :authorized_person_same_as_owner,
      :authorized_person_name,
      :authorized_person_title_division,
      :authorized_person_personal_id,
      :authorized_person_email,
      :authorized_person_mobile_number,
      :authorized_person_line_id,

      :contact_person_same_as_owner,
      :contact_person_same_as_authorized_person,
      :contact_person_name,
      :contact_person_title_division,
      :contact_person_personal_id,
      :contact_person_email,
      :contact_person_mobile_number,
      :contact_person_line_id
    )
  end
end
