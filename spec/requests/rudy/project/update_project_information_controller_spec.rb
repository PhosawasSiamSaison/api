require 'rails_helper'

RSpec.describe Rudy::Project::UpdateProjectInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
    let(:rudy_auth_token) { contractor_user.rudy_auth_token }
    let(:dealer) { FactoryBot.create(:b2b_dealer)}
    let(:site) { FactoryBot.create(:site, contractor: contractor, dealer: dealer, is_project: true) }
    let(:eligibility) { contractor.eligibilities.latest }

    before do
      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :b2b, eligibility: eligibility, limit_amount: 1000)
    end

    describe 'エラーチェック' do
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          project_code: site.site_code,
          project_name: "site1",
          project_credit_limit: 1000,
          auth_token: rudy_auth_token
        }
      }

      context 'project_codeの文字数超過' do
        let(:params) {
          default_params.merge({ new_project_code: 'a' * 16 })
        }

        it 'エラーになること' do
          post rudy_update_project_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'too_long_project_code'
        end
      end

      context 'project_nameの文字数超過' do
        let(:params) {
          default_params.merge({ project_name: 'a' * 256 })
        }

        it 'エラーになること' do
          post rudy_update_project_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'too_long_project_name'
        end
      end
    end

    it "正常値でSiteが正しく更新できること" do
      params = {
        tax_id: contractor.tax_id,
        project_code: site.site_code,
        new_project_code: "9999",
        project_name: "updated site name",
        project_credit_limit: 999,
        dealer_code: dealer.dealer_code,
        auth_token: rudy_auth_token,
      }

      post rudy_update_project_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      site = Site.first
      expect(site.site_code).to eq "9999"
      expect(site.site_name).to eq "updated site name"
      expect(site.site_credit_limit).to eq 999
    end
  end
end
