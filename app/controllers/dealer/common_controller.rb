# frozen_string_literal: true

class Dealer::CommonController < ApplicationController
  before_action :auth_user

  def header_info
    render json: {
      success:      true,
      login_user:   format_login_user(login_user),
      business_ymd: BusinessDay.business_ymd
    }
  end

  private

  def format_login_user (login_user)
    {
      id:        login_user.id,
      user_name: login_user.user_name,
      full_name: login_user.full_name,
      user_type: login_user.user_type_label
    }
  end
end
