# frozen_string_literal: true

class Jv::ContractorRegistrationController < ApplicationController
  include AvailableSettingsFormatterModule
  before_action :auth_user

  def available_settings
    # Draftの場合はcontractor_idが渡される
    contractor_id = params[:contractor_id]
    contractor_type = params[:contractor_type]

    if contractor_id.present?
      contractor = Contractor.find(contractor_id)
      contractor.contractor_type = contractor_type

      available_settings = format_available_settings(contractor)
    else
      available_settings = format_available_settings(contractor_type: contractor_type)
    end

    render json: {
      success: true,
      available_settings: available_settings,
    }
  end

  def register
    # Draftの続きをDraftで保存した場合はcontractor_idが渡される
    draft_contractor = params[:contractor_id] && Contractor.draft.find(params[:contractor_id])

    contractor = draft_contractor.presence || Contractor.new()
    contractor.set_values_for_register(login_user)
    contractor.main_dealer_id =
      params[:applied_dealers].present? ? params[:applied_dealers].first[:dealer_id] : nil

    contractor.approval_status = :draft if params[:save_as_draft]

    SetSameContractorUser.new(params, contractor).call

    errors = []
    ActiveRecord::Base.transaction do
      if contractor.update(register_contractor_params)
        # Applied Dealerの作成
        contractor.update_applied_dealers(params[:applied_dealers])

        # 購入・変更可能な商品の更新
        contractor.update_available_products(params[:available_settings])

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
  def register_contractor_params
    params.require(:contractor).permit(
      :doc_company_registration,
      :doc_vat_registration,
      :doc_owner_id_card,
      :doc_authorized_user_id_card,

      :doc_bank_statement,
      :doc_tax_report,

      :contractor_type,
      :use_only_credit_limit,
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

      :shareholders_equity,
      :recent_revenue,
      :short_term_loan,
      :long_term_loan,
      :recent_profit,

      :th_owner_name,
      :en_owner_name,
      :owner_address,
      :owner_sex,
      :owner_birth_ymd,
      :owner_personal_id,
      :owner_email,
      :owner_mobile_number,
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
