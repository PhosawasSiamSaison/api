# frozen_string_literal: true

class Contractor::UserUpdateController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def contractor_user
    contractor_user = login_user.contractor.contractor_users.find(params[:contractor_user_id])

    render json: { success: true, contractor_user: format_contractor_user(contractor_user) }
  end

  def update_user
    contractor_user = login_user.contractor.contractor_users.find(params[:contractor_user][:id])

    contractor_user.attributes = { update_user: login_user }

    if contractor_user.update(contractor_user_params)
      render json: { success: true }
    else
      render json: { success: false, errors: contractor_user.error_messages }
    end
  end

  def delete_user
    contractor_user = login_user.contractor.contractor_users.find(params[:contractor_user_id])

    if login_user.id == contractor_user.id
      return render json: { success: false, errors: set_errors('error_message.delete_own_account_error') }
    end

    contractor_user.delete_with_auth_tokens

    render json: { success: true }
  end

  private

  def contractor_user_params
    params.require(:contractor_user)
      .permit(:user_name, :full_name, :title_division, :mobile_number, :line_id, :email)
  end

  def format_contractor_user(contractor_user)
    {
      user_name:        contractor_user.user_name,
      full_name:        contractor_user.full_name,
      title_division:   contractor_user.title_division,
      mobile_number:    contractor_user.mobile_number,
      line_id:          contractor_user.line_id,
      email:            contractor_user.email,
      user_type:        contractor_user.user_type_label,
      create_user_name: contractor_user.masked_create_user.full_name,
      update_user_name: contractor_user.masked_update_user.full_name,
      created_at:       contractor_user.created_at,
      updated_at:       contractor_user.updated_at
    }
  end
end
