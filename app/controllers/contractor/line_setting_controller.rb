# frozen_string_literal: true

class Contractor::LineSettingController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def status
    contractor_user = login_user

    # LINEアプリを起動するためのURLを作成する
    line_id = JvService::Application.config.try(:line_bot_basic_id)

    line_link_account_word = JvService::Application.config.try(:line_link_account_word)
    text_message = URI.encode_www_form_component(line_link_account_word)

    url_scheme = "https://line.me/R/oaMessage/#{line_id}/?#{text_message}"

    render json: {
      success: true,
      is_linked: contractor_user.is_linked_line_account?,
      url_scheme: url_scheme,
    }
  end

  # アカウント連携の解除
  def delink_account
    contractor_user = login_user

    contractor_user.update!(line_user_id: nil, line_nonce: nil)

    render json: {
      success: true
    }
  end
end
