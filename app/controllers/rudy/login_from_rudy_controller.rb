# frozen_string_literal: true

class Rudy::LoginFromRudyController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    user_name = params[:username]
    password = params[:passcode]

    contractor_user = ContractorUser.find_by(user_name: user_name)
    raise(ValidationError, 'invalid_user') if contractor_user.blank?

    success = contractor_user.authenticate(password).present?
    raise(ValidationError, 'invalid_passcode') if !success

    return render json: {
      result: "OK"
    }
  end

  private
  def render_demo_response
    user_name = params[:username]

    return render json: { result: "OK" }       if user_name == 'user1'
    raise(ValidationError, 'invalid_user')     if user_name == 'user2'
    raise(ValidationError, 'not_agreed')       if user_name == 'user3'
    raise(ValidationError, 'invalid_passcode') if user_name == 'user4'

    raise NoCaseDemo
  end
end
