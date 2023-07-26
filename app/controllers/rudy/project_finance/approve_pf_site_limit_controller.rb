# frozen_string_literal: true

class Rudy::ProjectFinance::ApprovePfSiteLimitController < Rudy::ApplicationController
  def call
    site_code = params[:site_code]
    auth_token = params[:auth_token]

    # Siteチェック
    project_phase_site = ProjectPhaseSite.find_by(site_code: site_code)
    raise(ValidationError, 'site_not_found') if project_phase_site.blank?
    raise(ValidationError, 'site_closed')    if project_phase_site.closed?

    # Contractorチェック
    contractor = project_phase_site.contractor
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    # Contractor Userチェック
    contractor_user = contractor.contractor_users.find_by(rudy_auth_token: auth_token)
    raise(ValidationError, 'unverified') if auth_token.blank? || contractor_user.blank?

    site_limit_change_application = SiteLimitChangeApplication.find_by(project_phase_site: project_phase_site, approved: false)

    raise(ValidationError, 'no_valid_application') if site_limit_change_application.blank?

    ActiveRecord::Base.transaction do
      # ステータスの更新
      site_limit_change_application.update!(approved: true)

      # Site Limitの更新
      project_phase_site.update!(site_limit: site_limit_change_application.site_limit)
    end

    return render json: { result: 'OK' }
  end
end
