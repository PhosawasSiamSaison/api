# frozen_string_literal: true

class Rudy::Cpac::CreateSiteInformationController < Rudy::ApplicationController
  def call
    # return render_demo_response if get_demo_bearer_token?

    tax_id            = params[:tax_id]
    site_code         = params[:site_code]
    site_name         = params[:site_name]
    site_credit_limit = params[:site_credit_limit].to_f
    dealer_code       = params[:dealer_code]
    auth_token        = params[:auth_token]

    # Send New Site Information と共通のエラーチェック 
    error, result = create_site_error_check(true)
    return render json: result if error

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
    dealer = Dealer.find_by(dealer_code: dealer_code)

    site = Site.new
    site.contractor        = contractor
    site.site_code         = site_code
    site.site_name         = site_name
    site.site_credit_limit = site_credit_limit
    site.dealer            = dealer
    site.create_user       = contractor_user

    site.save!

    render json: {
      result: 'OK'
    }
  end
end
