# frozen_string_literal: true

class Contractor::UserRegistrationController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def create_user
    params[:contractor_user][:contractor_id] = login_user.contractor.id
    contractor_user = BuildContractorUser.new(params, login_user).call

    if contractor_user.save
      SendMessage.send_create_contractor_user(contractor_user)

      render json: { success: true }
    else
      render json: { success: false, errors: contractor_user.error_messages }
    end
  end
end
