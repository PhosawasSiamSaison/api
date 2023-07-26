# frozen_string_literal: true

class Rudy::Project::SendNewProjectInformationController < Rudy::ApplicationController
  def call
    # return render_demo_response if get_demo_bearer_token?

    tax_id            = params[:tax_id]
    site_code         = params[:project_code]
    site_name         = params[:project_name]
    site_credit_limit = params[:project_credit_limit].to_f
    url               = params[:url]
    dealer_code       = params[:dealer_code]

    # Create Site Information と共通のエラーチェック 
    error, result = create_site_error_check(false, is_project: true)
    return render json: result if error

    site_information = {
      site_code: site_code,
      site_credit_limit: site_credit_limit,
      url: url,
      servcie_name: Dealer.find_by!(dealer_code: dealer_code).dealer_type_setting.sms_servcie_name,
    }

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    contractor.contractor_users.each do |contractor_user|
      SendMessage.send_new_project_information(contractor_user, site_information)
    end

    render json: {
      result: 'OK'
    }
  end
end
