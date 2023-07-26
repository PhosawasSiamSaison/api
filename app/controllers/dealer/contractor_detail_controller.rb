# frozen_string_literal: true

class Dealer::ContractorDetailController < ApplicationController
  before_action :auth_user

  def basic_information
    contractor = find_contractor

    render json: { success: true, basic_information: format_basic_information(contractor) }
  end

  def contractor_users
    contractor = find_contractor

    render json: {
      success: true,
      contractor_users: format_contractor_users(contractor.contractor_users)
    }
  end

  def status
    contractor = find_contractor
    dealer = login_user.dealer

    render json: { success: true, status: format_status(contractor, dealer) }
  end

  def current_eligibility
    contractor = find_contractor
    dealer = login_user.dealer

    eligibility = {
      current_limit_amount: contractor.dealer_limit_amount(dealer)
    }

    render json: { success: true, eligibility: eligibility }
  end

  def more_information
    contractor = find_contractor
    contractor_view_formatter = ViewFormatter::ContractorFormatter.new(contractor)

    render json: {
      success: true,
      contractor: contractor_view_formatter.format_more_information_with_hash(
        {
          register_user_name: contractor.register_user&.full_name,
          create_user_name:   contractor.create_user&.full_name,
          update_user_name:   contractor.update_user&.full_name,
          approval_user_name: contractor.approval_user&.full_name,
        }
      )
    }
  end

  private
  def find_contractor
    login_user.dealer.contractors.find(params[:contractor_id])
  end

  def format_contractor_users(contractor_users)
    contractor_users.map do |contractor_user|
      {
        id:             contractor_user.id,
        user_name:      contractor_user.user_name,
        full_name:      contractor_user.full_name,
        mobile_number:  contractor_user.mobile_number,
        title_division: contractor_user.title_division,
        line_id:        contractor_user.line_id,
        user_type:      contractor_user.user_type_label,
      }
    end
  end

  def format_status(contractor, dealer)
    return {
      cashbacks_for_next_payment: contractor.cashback_amount,
      exceeded:                   contractor.exceeded_amount,
      available_balance:          contractor.dealer_available_balance(dealer),
      used_amount:                contractor.dealer_remaining_principal(dealer)
    }
  end

  def format_basic_information(contractor)
    return {
      tax_id:           contractor.tax_id,
      contractor_type:  contractor.contractor_type_label[:label],
      th_company_name:  contractor.th_company_name,
      en_company_name:  contractor.en_company_name,
      employee_count:   contractor.employee_count,
      status:           contractor.status_label,
      capital_fund_mil: contractor.capital_fund_mil,
      updated_at:       contractor.updated_at,
      approved_at:      contractor.approved_at
    }
  end

end
