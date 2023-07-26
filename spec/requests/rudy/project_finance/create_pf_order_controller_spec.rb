require 'rails_helper'

RSpec.describe Rudy::ProjectFinance::CreatePfOrderController, type: :request do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:product1) { Product.find_by(product_key: 1) }

  let(:project_manager) { FactoryBot.create(:project_manager, dealer_type: :solution)}
  let(:project) { FactoryBot.create(:project, project_manager: project_manager) }
  let(:project_phase) { FactoryBot.create(:project_phase, :opened, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase,
    contractor: contractor, site_limit: 100) }
  let(:sol_dealer) { FactoryBot.create(:sol_dealer) }

  let(:default_params) {
    {
      tax_id: contractor.tax_id,
      site_code: project_phase_site.site_code,
      order_number: "12345",
      product_id: product1.product_key,
      dealer_code: sol_dealer.dealer_code,
      second_dealer_code: nil,
      purchase_date: "20220112",
      amount: 105,
      second_dealer_amount: 0,
      amount_without_tax: 100,
      region: 'sample region',
    }
  }

  before do
    FactoryBot.create(:business_day, business_ymd: '20220112')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)

    GlobalAvailableSetting.where(dealer_type: :cbm).update_all(available: false)
  end

  after do
    GlobalAvailableSetting.where(dealer_type: :cbm).update_all(available: true)
  end

  describe "POST #call" do
    it 'Orderが正しく登録される事' do
      params = default_params.dup

      post rudy_create_project_finance_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      expect(Order.count).to eq 1
      order = Order.first

      expect(order.order_number).to eq '12345'
      expect(order.contractor).to eq contractor
      expect(order.site).to eq nil
      expect(order.project_phase_site).to eq project_phase_site
      expect(order.dealer).to eq sol_dealer
      expect(order.second_dealer).to eq nil
      expect(order.product.product_key).to eq product1.product_key
      expect(order.installment_count).to eq 1
      expect(order.purchase_ymd).to eq '20220112'
      expect(order.purchase_amount).to eq 105
      expect(order.amount_without_tax).to eq 100
      expect(order.second_dealer_amount).to eq 0
      expect(order.paid_up_ymd).to eq nil
      expect(order.input_ymd).to eq nil
      expect(order.input_ymd_updated_at).to eq nil
      expect(order.order_user).to eq nil
      expect(order.region).to eq 'sample region'
    end

    context 'Phase.Statusがnot_opened_yet' do
      before do
        project_phase.not_opened_yet!
      end

      it 'エラーが返ること' do
        params = default_params.dup

        post rudy_create_project_finance_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'PHASE_NOT_OPEN'
      end
    end

    context 'Project系以外のDealer' do
      let(:dealer) { FactoryBot.create(:cbm_dealer) }

      it 'オーダーができること' do
        params = default_params.dup
        params[:dealer_code] = dealer.dealer_code

        post rudy_create_project_finance_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'
        order = Order.first
        expect(order.dealer.project_group?).to eq false
      end
    end

    describe 'エラー検証' do
      it 'site_not_found' do
        params = default_params.dup
        params[:site_code] = 'not_exists_site_code'

        post rudy_create_project_finance_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'site_not_found'
      end

      describe 'Available Setting' do
        it 'Project Managerのdealer_typeの設定で判定すること' do
          project_manager.update!(dealer_type: :cbm)

          params = default_params.dup
          post rudy_create_project_finance_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'unavailable_purchase_setting'
        end
      end
    end
  end
end
