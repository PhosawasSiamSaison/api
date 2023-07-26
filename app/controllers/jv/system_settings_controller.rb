# frozen_string_literal: true

class Jv::SystemSettingsController < ApplicationController
  before_action :auth_user

  def settings
    settings = {
      verify_mode: SystemSetting.verify_mode,
      sms_provider: SystemSetting.sms_provider,
      can_update: permission_errors(login_user).blank?,
    }

    render json: {
      success: true,
      settings: settings,
    }
  end

  def update_settings
    # 権限チェック
    errors = permission_errors(login_user)

    if errors.present?
      return render json: {
        success: false,
        errors: errors
      }
    end

    SystemSetting.update!(system_settings_params)

    render json: {
      success: true
    }
  end

  private
  def permission_errors(login_user)
    check_permission_errors(login_user.md?)
  end

  def system_settings_params
    params.require(:settings).permit(:verify_mode, :sms_provider)
  end
end
