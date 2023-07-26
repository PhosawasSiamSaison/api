require 'rails_helper'

RSpec.describe Rudy::Cpac::SendNewSiteInformationController, type: :request do
  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)
  end

  describe "POST #call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:dealer) { FactoryBot.create(:cpac_dealer)}
    let(:eligibility) { contractor.eligibilities.latest }

    before do
      FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer, limit_amount: 1000)
      FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility, limit_amount: 1000)
      FactoryBot.create(:contractor_user, contractor: contractor)
    end

    describe 'エラーチェック' do
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          site_code: "12345",
          site_name: "hoge",
          site_credit_limit: 1000,
          dealer_code: dealer.dealer_code,
        }
      }

      context 'site_codeの文字数超過' do
        let(:params) {
          default_params.merge({ site_code: 'a' * 16 })
        }

        it 'エラーになること' do
          post rudy_send_new_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'too_long_site_code'
        end
      end

      context 'site_nameの文字数超過' do
        let(:params) {
          default_params.merge({ site_name: 'a' * 256 })
        }

        it 'エラーになること' do
          post rudy_send_new_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'too_long_site_name'
        end
      end
    end

    describe 'SMS' do
      let(:params) {
        {
          tax_id: contractor.tax_id,
          site_code: "12345",
          site_name: "hoge",
          site_credit_limit: 1000,
          dealer_code: dealer.dealer_code,
        }
      }

      context 'CPAC' do
        let(:dealer) { FactoryBot.create(:cpac_dealer) }

        it "SMSが送信されること" do
          post rudy_send_new_site_information_path, params: params, headers: headers

          expect(res[:result]).to eq 'OK'

          sms = SmsSpool.first

          expect(sms.present?).to eq true
          expect(sms.message_type).to eq "new_site_information"
        end
      end
    end
  end
end
