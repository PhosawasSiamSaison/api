# frozen_string_literal: true

class Rudy::ProjectFinance::SetPfSiteLimitController < Rudy::ApplicationController
  def call
    site_code = params.fetch(:site_code)
    site_limit = params.fetch(:site_credit_limit).to_f
    url = params[:url]

    # Siteチェック
    project_phase_site = ProjectPhaseSite.find_by(site_code: site_code)
    raise(ValidationError, 'site_not_found') if project_phase_site.blank?
    raise(ValidationError, 'site_closed')    if project_phase_site.closed?

    # Contractorチェック
    contractor = project_phase_site.contractor
    raise(ValidationError, 'contractor_not_found')   if contractor.blank?
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?


    # 金額チェック
    if invalid_amount?(site_limit)
      raise(ValidationError, 'amount_without_tax is not valid')
    end
    
    # Site Limit 上限チェック
    raise(ValidationError, 'over_phase_limit') if site_limit > project_phase_site.phase_limit

    # 既存レコードがある場合は削除する
    site_limit_change_application = SiteLimitChangeApplication.find_by(project_phase_site: project_phase_site)
    if site_limit_change_application.present?
      site_limit_change_application.delete
    end

    # 申請テーブルにレコードを作成
    SiteLimitChangeApplication.create!(project_phase_site: project_phase_site, site_limit: site_limit)

    # SMS文面で使用するデータ
    site_information = {
      servcie_name: 'SAISON CREDIT', # 固定値を使用
      site_code: site_code,
      current_site_credit_limit: project_phase_site.site_limit,
      adjusted_site_credit_limit: site_limit,
      url: url,
    }

    # SMS送信
    SendMessage.set_pf_site_limit(contractor, site_information)

    return render json: { result: 'OK' }
  end
end
