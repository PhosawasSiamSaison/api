# frozen_string_literal: true

class Contractor::QrCodeForPaymentController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def qr_code
    contractor = login_user.contractor
    qr_code_image_url = contractor.qr_code_image.attached? ? url_for(contractor.qr_code_image) : nil

    render json: {
      success: true,
      qr_code_image_url: qr_code_image_url,
    }
  end
end
