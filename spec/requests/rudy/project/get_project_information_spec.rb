require 'rails_helper'

RSpec.describe Rudy::Project::GetProjectInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer) { FactoryBot.create(:dealer, :b2b)}
    let(:site) { FactoryBot.create(:site, contractor: contractor, is_project: true) }

    before do
      FactoryBot.create(:eligibility, contractor: contractor)
    end

    it "正常にレスポンスが返ること" do
      params = {
        tax_id: contractor.tax_id,
        project_code: site.site_code
      }

      get rudy_get_project_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'
      expect(res[:project_name]).to eq site.site_name
      expect(res[:project_credit_limit]).to eq site.site_credit_limit
      expect(res[:project_credit_limit].is_a?(Float)).to eq true
      expect(res[:project_used_amount]).to eq site.remaining_principal
      expect(res[:project_available_balance]).to eq site.available_balance
      expect(res[:project_closed]).to eq false
    end

    describe "エラーレスポンス" do
      it 'project_not_foundが返ること' do
        params = {
          tax_id: contractor.tax_id,
          project_code: "aaaa"
        }

        get rudy_get_project_information_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'project_not_found'
      end
    end
  end
end
