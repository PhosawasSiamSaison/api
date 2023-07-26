require 'rails_helper'

RSpec.describe Rudy::Cpac::GetSiteInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer) { FactoryBot.create(:dealer, :cpac)}
    let(:site) { FactoryBot.create(:site, contractor: contractor) }

    before do
      FactoryBot.create(:eligibility, contractor: contractor)
    end

    it "正常にレスポンスが返ること" do
      params = {
        tax_id: contractor.tax_id,
        site_code: site.site_code
      }

      get rudy_get_site_information_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'
      expect(res[:site_name]).to eq site.site_name
      expect(res[:site_credit_limit]).to eq site.site_credit_limit
      expect(res[:site_credit_limit].is_a?(Float)).to eq true
      expect(res[:site_used_amount]).to eq site.remaining_principal
      expect(res[:site_available_balance]).to eq site.available_balance
      expect(res[:site_closed]).to eq false
    end

    describe "エラーレスポンス" do
      it 'site_not_foundが返ること' do
        params = {
          tax_id: contractor.tax_id,
          site_code: "aaaa"
        }

        get rudy_get_site_information_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'site_not_found'
      end
    end
  end
end
