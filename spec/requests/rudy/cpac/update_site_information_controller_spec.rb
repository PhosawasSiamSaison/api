require 'rails_helper'

RSpec.describe Rudy::Cpac::UpdateSiteInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
    let(:rudy_auth_token) { contractor_user.rudy_auth_token }
    let(:dealer) { FactoryBot.create(:cpac_dealer)}
    let(:site) { FactoryBot.create(:site, contractor: contractor, dealer: dealer, site_credit_limit: 1000) }
    let(:eligibility) { contractor.eligibilities.latest }

    before do
      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility, limit_amount: 1000)
    end

    describe 'エラーチェック' do
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          site_code: site.site_code,
          site_name: "site1",
          site_credit_limit: 1000,
          dealer_code: dealer.dealer_code,
          auth_token: rudy_auth_token
        }
      }

      context 'site_codeの文字数超過' do
        let(:params) {
          default_params.merge({ new_site_code: 'a' * 16 })
        }

        it 'エラーになること' do
          post rudy_update_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'too_long_site_code'
        end
      end

      context 'site_nameの文字数超過' do
        let(:params) {
          default_params.merge({ site_name: 'a' * 256 })
        }

        it 'エラーになること' do
          post rudy_update_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'too_long_site_name'
        end
      end

      describe 'over_dealer_limit' do
        let(:params) {
          default_params.merge({ site_credit_limit: 1100 })
        }

        it 'over_dealer_limitのエラーが返ること' do
          post rudy_update_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'over_dealer_limit'
        end
      end

      describe 'over_credit_limit' do
        let(:params) {
          default_params.merge({ site_credit_limit: 1100 })
        }

        before do
          contractor.update!(use_only_credit_limit: true)
        end

        it 'over_credit_limitのエラーが返ること' do
          post rudy_update_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'over_credit_limit'
        end
      end
    end

    it "正常値でSiteが正しく更新できること" do
      params = {
        tax_id: contractor.tax_id,
        site_code: site.site_code,
        new_site_code: "9999",
        site_name: "updated site name",
        site_credit_limit: 999,
        dealer_code: dealer.dealer_code,
        auth_token: rudy_auth_token,
      }

      post rudy_update_site_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      site = Site.first
      expect(site.site_code).to eq "9999"
      expect(site.site_name).to eq "updated site name"
      expect(site.site_credit_limit).to eq 999
    end
  end
end
