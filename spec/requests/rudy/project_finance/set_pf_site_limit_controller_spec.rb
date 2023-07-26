require 'rails_helper'

RSpec.describe Rudy::ProjectFinance::SetPfSiteLimitController, type: :request do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:product1) { Product.find_by(product_key: 1) }

  let(:project) { FactoryBot.create(:project) }
  let(:project_phase) { FactoryBot.create(:project_phase, :opened, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase,
    contractor: contractor, phase_limit: 100, site_limit: 0) }
  let(:sol_dealer) { FactoryBot.create(:sol_dealer) }

  let(:default_params) {
    {
      site_code: project_phase_site.site_code,
      site_credit_limit: 0,
      url: "sms-url",
    }
  }

  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)

    # SMS確認用
    FactoryBot.create(:contractor_user, contractor: contractor)
  end

  describe "POST #call" do
    it '正しく処理されること' do
      params = default_params.dup
      params[:site_credit_limit] = 90

      post rudy_set_project_finance_site_limit_path, params: params, headers: headers
      expect(res[:result]).to eq 'OK'

      expect(SiteLimitChangeApplication.count).to eq 1
      site_limit_change_application = SiteLimitChangeApplication.first

      expect(site_limit_change_application.site_limit).to eq 90
      expect(site_limit_change_application.approved).to eq false

      # Site Limitが更新されていないこと
      expect(project_phase_site.site_limit).to eq 0

      # SMSが作成されること
      sms = SmsSpool.set_pf_site_limit.first
      expect(sms.present?).to eq true
      expect(sms.message_body.include?("0")).to eq true
      expect(sms.message_body.include?("90")).to eq true
      expect(sms.message_body.include?("sms-url")).to eq true
    end

    it '同じsiteの複数のリクエストでもレコードは最新が１つだけあること' do
      params = default_params.dup

      params[:site_credit_limit] = 90
      post rudy_set_project_finance_site_limit_path, params: params, headers: headers
      expect(res[:result]).to eq 'OK'

      params[:site_credit_limit] = 80
      post rudy_set_project_finance_site_limit_path, params: params, headers: headers
      expect(res[:result]).to eq 'OK'

      expect(SiteLimitChangeApplication.count).to eq 1
      site_limit_change_application = SiteLimitChangeApplication.first

      expect(site_limit_change_application.site_limit).to eq 80
    end

    it 'siteがclosedの場合はエラーが返ること' do
      project_phase_site.closed!
      project_phase_site.reload

      params = default_params.dup
      params[:site_credit_limit] = 90

      post rudy_set_project_finance_site_limit_path, params: params, headers: headers
      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'site_closed'

      expect(SiteLimitChangeApplication.count).to eq 0

      # Site Limitが更新されていないこと
      expect(project_phase_site.site_limit).to eq 0

      # SMSが作成されないこと
      expect(SmsSpool.set_pf_site_limit.count).to eq 0
    end

    it 'phase_limitを超えた場合はエラーが返ること' do
      params = default_params.dup
      params[:site_credit_limit] = 101

      post rudy_set_project_finance_site_limit_path, params: params, headers: headers
      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'over_phase_limit'

      expect(SiteLimitChangeApplication.count).to eq 0

      # Site Limitが更新されていないこと
      expect(project_phase_site.site_limit).to eq 0

      # SMSが作成されないこと
      expect(SmsSpool.set_pf_site_limit.count).to eq 0
    end

    context do
      before do
        FactoryBot.create(:project_phase_site, site_code: "site2", project_phase: project_phase, phase_limit: 100, site_limit: 0)
      end

      it '異なるSiteのリクエストでレコードが複数作成されること' do
        params = default_params.dup

        params[:site_credit_limit] = 90
        post rudy_set_project_finance_site_limit_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'

        params[:site_code] = "site2"
        params[:site_credit_limit] = 80
        post rudy_set_project_finance_site_limit_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'

        expect(SiteLimitChangeApplication.count).to eq 2
      end
    end
  end
end
