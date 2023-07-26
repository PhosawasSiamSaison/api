# frozen_string_literal: true

class Contractor::CommonController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def check_permission
    # before_actionでエラーにならなければOK
    render json: { success: true }
  end
end
