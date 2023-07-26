# frozen_string_literal: true

class Dealer::TermsOfServiceController < ApplicationController
  before_action :auth_user

  def agreed
    login_user.update!(agreed_at: Time.zone.now)

    render json: { success: true }
  end
end
