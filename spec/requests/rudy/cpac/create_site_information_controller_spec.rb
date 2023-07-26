require 'rails_helper'

RSpec.describe Rudy::Cpac::CreateSiteInformationController, type: :request do
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
    let(:eligibility) { contractor.eligibilities.latest }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        site_code: "12345",
        site_name: "hoge",
        site_credit_limit: 1000,
        dealer_code: dealer.dealer_code,
        auth_token: rudy_auth_token,
      }
    }

    before do
      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility, limit_amount: 1000)
    end

    it "サイトが正しく作成されること" do
      params = default_params.dup

      post rudy_create_site_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'
      expect(Site.count).to eq 1
      site = Site.first
      expect(site.site_code).to eq params[:site_code]
      expect(site.site_name).to eq params[:site_name]
      expect(site.site_credit_limit).to eq params[:site_credit_limit]
    end

    describe 'over_dealer_limit' do
      before do
        contractor.latest_dealer_limits.first.update!(limit_amount: 1)
      end

      it 'エラーが返ること' do
        post rudy_create_site_information_path, params: default_params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_limit'
        expect(res[:available_balance]).to eq 1
      end
    end

    describe 'over_dealer_type_limit' do
      before do
        contractor.latest_dealer_type_limits.first.update!(limit_amount: 2)
      end

      it 'エラーが返ること' do
        post rudy_create_site_information_path, params: default_params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_type_limit'
        expect(res[:available_balance]).to eq 2
      end
    end

    it "contractor_not_found" do
      params = {
        tax_id: "000",
        site_code: "12345",
        site_name: "hoge",
        site_credit_limit: 1000,
        auth_token: rudy_auth_token
      }

      post rudy_create_site_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'contractor_not_found'
    end

    describe 'duplicate_site_code' do
      before do
        FactoryBot.create(:site, site_code: 'site1')
        FactoryBot.create(:project_phase_site, site_code: 'site2')
      end

      it 'エラーが返ること' do
        params = default_params.dup

        # site
        params[:site_code] = 'site1'
        post rudy_create_site_information_path, params: params, headers: headers
        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'duplicate_site_code'

        # project_phase_site
        params[:site_code] = 'site2'
        post rudy_create_site_information_path, params: params, headers: headers
        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'duplicate_site_code'

        # success
        params[:site_code] = 'site3'
        post rudy_create_site_information_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'
      end
    end
  end
end
