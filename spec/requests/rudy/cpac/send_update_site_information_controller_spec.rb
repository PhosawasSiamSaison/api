require 'rails_helper'

RSpec.describe Rudy::Cpac::SendUpdateSiteInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer) { FactoryBot.create(:cpac_dealer)}
    let(:site) { FactoryBot.create(:site, contractor: contractor, dealer: dealer, site_credit_limit: 1000) }
    let(:eligibility) { contractor.eligibilities.latest }

    before do
      FactoryBot.create(:contractor_user, contractor: contractor)

      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility, limit_amount: 1000)

      order = FactoryBot.create(:order, contractor: contractor, site: site)
      FactoryBot.create(:installment, order: order, principal: 1000, paid_principal: 0)
    end

    describe 'SMS' do
      let(:params) {
        {
          tax_id: contractor.tax_id,
          site_code: site.site_code,
          site_name: "updated site name",
          site_credit_limit: 1000,
          dealer_code: dealer.dealer_code,
        }
      }

      it "SMSが送信されること" do
        post rudy_send_update_site_information_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        sms = SmsSpool.first
        expect(sms.present?).to eq true
        expect(sms.message_type).to eq "update_site_information"
      end
    end

    describe 'Limitのチェック' do
      let(:params) {
        {
          tax_id: contractor.tax_id,
          site_code: site.site_code,
          site_name: "updated site name",
          site_credit_limit: 1001,
          dealer_code: dealer.dealer_code,
        }
      }

      it "エラーにならないこと" do
        post rudy_send_update_site_information_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'
      end
    end
  end
end
