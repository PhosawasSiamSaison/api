# frozen_string_literal: true

class Rudy::Cpac::CloseSiteInformationController < Rudy::ApplicationController
  def call
    # return render_demo_response if get_demo_bearer_token?

    tax_id    = params[:tax_id]
    site_code = params[:site_code]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    site = contractor.sites.not_projects.find_by(site_code: site_code)
    raise(ValidationError, 'site_not_found') if site.blank?
    raise(ValidationError, 'site_closed')    if site.closed?

    site.update!(closed: true)

    render json: {
      result: 'OK'
    }
  end
end
