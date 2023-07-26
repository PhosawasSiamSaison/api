require 'rails_helper'

RSpec.describe Rudy::Project::CreateProjectOrderController, type: :request do
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
  let(:dealer) { FactoryBot.create(:b2b_dealer)}
  let(:second_dealer) { FactoryBot.create(:dealer)}
  let(:site) { FactoryBot.create(:site, is_project: true, contractor: contractor,
    site_credit_limit: 1000) }
  let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)

    pdpa_version = FactoryBot.create(:pdpa_version)
    FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
      pdpa_version: pdpa_version)
  end

  describe "POST #call" do
    before do
      FactoryBot.create(:dealer_type_limit, :b2b, eligibility: eligibility)
      FactoryBot.create(:dealer_limit, dealer: dealer, eligibility: eligibility)
    end

    it 'Orderが正しく登録される事' do
      params = {
        tax_id: contractor.tax_id,
        project_code: site.site_code,
        order_number: "12345",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        second_dealer_code: second_dealer.dealer_code,
        purchase_date: "20190101",
        amount: 100,
        second_dealer_amount: 10,
        amount_without_tax: 90,
        region: 'sample region',
      }

      post rudy_create_project_order_path, params: params, headers: headers

      expect(response).to have_http_status(:success)
      expect(res[:result]).to eq 'OK'

      expect(Order.count).to eq 1
      order = Order.first

      expect(order.order_number).to eq '12345'
      expect(order.contractor).to eq contractor
      expect(order.site).to eq site
      expect(order.dealer).to eq dealer
      expect(order.second_dealer).to eq second_dealer
      expect(order.product.product_key).to eq 1
      expect(order.installment_count).to eq 1
      expect(order.purchase_ymd).to eq '20190101'
      expect(order.purchase_amount).to eq 100.0
      expect(order.amount_without_tax).to eq 90.0
      expect(order.second_dealer_amount).to eq 10.0
      expect(order.paid_up_ymd).to eq nil
      expect(order.input_ymd).to eq nil
      expect(order.input_ymd_updated_at).to eq nil
      expect(order.order_user).to eq nil
      expect(order.region).to eq 'sample region'
    end

    describe '重複チェック' do
      it "duplicate_orderが返ること" do
        params = {
          tax_id: contractor.tax_id,
          project_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 100,
          amount_without_tax: 900,
          region: 'sample region',
        }

        post rudy_create_project_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        post rudy_create_project_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'duplicate_order'
      end

      describe '一意制約のチェック' do
        let(:default_params) {
          {
            tax_id: contractor.tax_id,
            project_code: site.site_code,
            order_number: "1",
            product_id: 1,
            dealer_code: dealer.dealer_code,
            purchase_date: '20190101',
            amount: 100,
            amount_without_tax: 900,
            region: 'sample region',
          }
        }

        it '異なるorder_numberで登録できること' do
          params = default_params.dup

          post rudy_create_project_order_path, params: params, headers: headers
          expect(res[:result]).to eq 'OK'

          params[:order_number] = "aaa"

          post rudy_create_project_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'OK'
        end

        context '異なるdealer' do
          before do
            dealer = FactoryBot.create(:b2b_dealer, dealer_code: "8931")

            FactoryBot.create(:order, contractor: contractor, dealer: dealer, site: site,
              order_number: default_params[:order_number], purchase_amount: 900)
          end

          it '登録できること' do
            params = default_params.dup
            params[:dealer_code] = dealer.dealer_code

            post rudy_create_project_order_path, params: params, headers: headers

            expect(res[:result]).to eq 'OK'
          end
        end

        context '異なるSiteCode' do
          before do
            site = FactoryBot.create(:site, contractor: contractor, site_code: "8931")

            FactoryBot.create(:order, contractor: contractor, dealer: dealer, site: site,
              order_number: default_params[:order_number], purchase_amount: 900)
          end

          it '登録できないこと' do
            params = default_params.dup
            params[:site_code] = site.site_code

            post rudy_create_project_order_path, params: params, headers: headers

            expect(res[:result]).to eq 'NG'
            expect(res[:error]).to eq 'duplicate_order'
          end
        end
      end
    end
  end
end
