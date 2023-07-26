# frozen_string_literal: true

class Rudy::Project::CloseProjectInformationController < Rudy::ApplicationController
  def call
    # return render_demo_response if get_demo_bearer_token?

    tax_id    = params[:tax_id]
    site_code = params[:project_code]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    site = contractor.sites.is_projects.find_by(site_code: site_code)
    raise(ValidationError, 'project_not_found') if site.blank?
    raise(ValidationError, 'project_closed')    if site.closed?

    site.update!(closed: true)

    render json: {
      result: 'OK'
    }
  end
end
