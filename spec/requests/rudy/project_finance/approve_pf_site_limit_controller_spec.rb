require 'rails_helper'

RSpec.describe Rudy::ProjectFinance::ApprovePfSiteLimitController, type: :request do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }

  let(:project) { FactoryBot.create(:project) }
  let(:project_phase) { FactoryBot.create(:project_phase, :opened, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase,
    contractor: contractor, phase_limit: 100, site_limit: 0) }
  let(:sol_dealer) { FactoryBot.create(:sol_dealer) }

  let(:default_params) {
    {
      auth_token: contractor_user.rudy_auth_token,
      site_code: project_phase_site.site_code,
    }
  }

  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    before do
      FactoryBot.create(:site_limit_change_application, project_phase_site: project_phase_site, site_limit: 90)
    end

    let(:site_limit_change_application) { SiteLimitChangeApplication.first }

    it '正しく処理されること' do
      params = default_params.dup

      post rudy_approve_project_finance_site_path, params: params, headers: headers
      expect(res[:result]).to eq 'OK'

      expect(site_limit_change_application.reload.approved).to eq true

      # Site Limitが更新されること
      expect(project_phase_site.reload.site_limit).to eq 90
    end

    it '完了した申請が再度承認されないこと' do
      site_limit_change_application.update!(approved: true)

      params = default_params.dup

      post rudy_approve_project_finance_site_path, params: params, headers: headers
      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'no_valid_application'

      # Site Limitが更新されないこと
      expect(project_phase_site.reload.site_limit).to eq 0
    end

    it 'phase_limitを超えていても更新できること(承認時はエラーチェックをしない)' do
      project_phase_site.update!(phase_limit: 0)

      params = default_params.dup

      post rudy_approve_project_finance_site_path, params: params, headers: headers
      expect(res[:result]).to eq 'OK'
      project_phase_site.reload

      expect(site_limit_change_application.approved).to eq true

      # Site Limitが更新されること
      expect(project_phase_site.site_limit).to eq 90

      expect(project_phase_site.site_limit > project_phase_site.phase_limit).to eq true
    end
  end
end
