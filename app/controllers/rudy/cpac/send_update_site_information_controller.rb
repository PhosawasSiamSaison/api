# frozen_string_literal: true

class Rudy::Cpac::SendUpdateSiteInformationController < Rudy::ApplicationController
  def call
    # return render_demo_response if get_demo_bearer_token?

    tax_id            = params[:tax_id]
    site_code         = params[:site_code]
    new_site_code     = params[:new_site_code]
    site_name         = params[:site_name]
    site_credit_limit = params[:site_credit_limit].to_f
    url               = params[:url]
    dealer_code       = params[:dealer_code]

    # Update Site Information と共通のエラーチェック 
    error, result = update_site_error_check(false)
    return render json: result if error

    dealer = Dealer.find_by!(dealer_code: dealer_code)

    site_information = {
      servcie_name: dealer.dealer_type_setting.sms_servcie_name,
      site_code: site_code,
      current_site_credit_limit: Site.find_by(site_code: site_code).site_credit_limit,
      adjusted_site_credit_limit: site_credit_limit,
      url: url,
    }

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    contractor.contractor_users.each do |contractor_user|
      SendMessage.send_update_site_information(contractor_user, site_information)
    end

    render json: {
      result: 'OK'
    }
  end
end