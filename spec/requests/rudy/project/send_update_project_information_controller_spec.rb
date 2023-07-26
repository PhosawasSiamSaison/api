require 'rails_helper'

RSpec.describe Rudy::Project::SendUpdateProjectInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer) { FactoryBot.create(:b2b_dealer)}
    let(:site) { FactoryBot.create(:site, is_project: true, contractor: contractor, dealer: dealer,
      site_credit_limit: 1000) }
    let(:eligibility) { contractor.eligibilities.latest }

    before do
      FactoryBot.create(:contractor_user, contractor: contractor)

      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :b2b, eligibility: eligibility, limit_amount: 1000)

      order = FactoryBot.create(:order, contractor: contractor, site: site)
      FactoryBot.create(:installment, order: order, principal: 1000, paid_principal: 0)
    end

    describe 'SMS' do
      let(:params) {
        {
          tax_id: contractor.tax_id,
          project_code: site.site_code,
          project_name: "updated site name",
          project_credit_limit: 1000,
          dealer_code: dealer.dealer_code,
        }
      }

      it "SMSが送信されること" do
        post rudy_send_update_project_information_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        sms = SmsSpool.first
        expect(sms.present?).to eq true
        expect(sms.message_type).to eq "update_project_information"
      end
    end

    describe 'Limitのチェック' do
      let(:params) {
        {
          tax_id: contractor.tax_id,
          project_code: site.site_code,
          project_name: "updated site name",
          project_credit_limit: 1001,
          dealer_code: dealer.dealer_code,
        }
      }

      it "エラーにならないこと" do
        post rudy_send_update_project_information_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'
      end
    end
  end
end
