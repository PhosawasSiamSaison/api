# frozen_string_literal: true

class Contractor::UserVerifyModeController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def verify_mode
    contractor_user = login_user

    render json: { success: true, verify_mode: contractor_user.verify_mode_label[:label] }
  end

  # Edit画面で必要な値を渡す
  def verify_mode_info
    contractor_user = login_user

    render json: { success: true, verify_mode: contractor_user.verify_mode }
  end

  def send_otp_message
    contractor_user = login_user

    otp = contractor_user.generate_otp
    contractor_user.update!(verify_mode_otp: otp)

    SendMessage.change_user_verify_mode_otp(contractor_user, otp)

    render json: { success: true }
  end

  def update_verify_mode
    contractor_user = login_user
    otp = params[:passcode]
    verify_mode = params[:verify_mode]

    if otp != contractor_user.verify_mode_otp
      return render json: { success: false, error: I18n.t('error_message.invalid_passcode') }
    end

    contractor_user.update!(verify_mode: verify_mode, verify_mode_otp: nil)

    render json: { success: true }
  end
end
