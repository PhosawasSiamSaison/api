# frozen_string_literal: true

class Rudy::Project::GetProjectInformationController < Rudy::ApplicationController
  def call
    tax_id    = params[:tax_id]
    site_code = params[:project_code]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    site = contractor.sites.is_projects.find_by(site_code: site_code)
    raise(ValidationError, 'project_not_found') if site.blank?

    render json: {
      result: 'OK',
      project_name:              site.site_name,
      project_credit_limit:      site.site_credit_limit.to_f,
      project_used_amount:       site.remaining_principal,
      project_available_balance: site.available_balance,
      project_closed:            site.closed?,
    }
  end
end
