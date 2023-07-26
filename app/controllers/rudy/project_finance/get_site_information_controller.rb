# frozen_string_literal: true

class Rudy::ProjectFinance::GetSiteInformationController < Rudy::ApplicationController
  def call
    tax_id    = params[:tax_id]
    site_code = params[:site_code]

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    site = contractor.project_phase_sites.find_by(site_code: site_code)
    raise(ValidationError, 'site_not_found') if site.blank?

    render json: {
      result: 'OK',
      site_name:              site.site_name,
      contractor_phase_limit: site.phase_limit.to_f,
      site_credit_limit:      site.site_limit.to_f,
      site_used_amount:       site.used_amount,
      site_available_balance: site.available_balance,
      site_closed:            site.closed?,
    }
  end
end
