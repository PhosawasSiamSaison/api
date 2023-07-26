# frozen_string_literal: true

class Jv::ContractorUserRegistrationController < ApplicationController
  before_action :auth_user

  def create_contractor_user
    contractor_user = BuildContractorUser.new(params, login_user).call

    if contractor_user.save
      SendMessage.send_create_contractor_user(contractor_user)

      render json: { success: true }
    else
      render json: { success: false, errors: contractor_user.error_messages }
    end
  end
end
