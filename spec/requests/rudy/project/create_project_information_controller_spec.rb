require 'rails_helper'

RSpec.describe Rudy::Project::CreateProjectInformationController, type: :request do
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
    let(:eligibility) { contractor.eligibilities.latest }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        project_code: "12345",
        project_name: "hoge",
        project_credit_limit: 1000,
        dealer_code: dealer.dealer_code,
        auth_token: rudy_auth_token,
      }
    }

    before do
      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :b2b, eligibility: eligibility, limit_amount: 1000)
    end

    it "サイトが正しく作成されること" do
      params = default_params.dup

      post rudy_create_project_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'
      expect(Site.count).to eq 1
      site = Site.first
      expect(site.site_code).to eq params[:project_code]
      expect(site.site_name).to eq params[:project_name]
      expect(site.site_credit_limit).to eq params[:project_credit_limit]
    end

    describe 'over_dealer_limit' do
      before do
        contractor.latest_dealer_limits.first.update!(limit_amount: 1)
      end

      it 'エラーが返ること' do
        post rudy_create_project_information_path, params: default_params, headers: headers

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
        post rudy_create_project_information_path, params: default_params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_type_limit'
        expect(res[:available_balance]).to eq 2
      end
    end

    it "contractor_not_found" do
      params = {
        tax_id: "000",
        project_code: "12345",
        project_name: "hoge",
        project_credit_limit: 1000,
        auth_token: rudy_auth_token
      }

      post rudy_create_project_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'contractor_not_found'
    end
  end
end
