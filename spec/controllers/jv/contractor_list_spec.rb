require 'rails_helper'

RSpec.describe Jv::ContractorListController, type: :controller do

  describe '#controctor_serach ' do
    before do
      contractor = FactoryBot.create(:contractor, :qualified, tax_id: "1234567890123")
      FactoryBot.create(:eligibility, :latest, contractor: contractor)
    end

    let(:contractor) { FactoryBot.create(:contractor, :qualified, tax_id: "1234567890124") }
    let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        page: 1,
        per_page: 10,
        search: {
          tax_id: "",
          contractor_type: "",
          company_name: "",
          show_inactive_only: "",
          dealer_id: "",
          dealer_type: "",
        },
      }
    }

    describe 'params文字チェック' do
      it 'パラメーターが正しくパースされること' do
        params = {
          auth_token: auth_token.token,
          search: "{\"tax_id\": \"1234567890123\"}",
        }

        get :search, params: params

        expect(res[:success]).to eq true
        expect(res[:contractors].count).to eq 1
        expect(res[:total_count]).to eq 1
      end
    end

    describe '条件' do
      describe 'dealer_type' do
        before do
          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
        end

        it '指定のdealer_typeで取得できること' do
          params = default_params.dup
          params[:search][:dealer_type] = "cbm"

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:contractors].count).to eq 1
          expect(res[:total_count]).to eq 1
        end

        it '指定のdealer_typeで取得ができないこと' do
          params = default_params.dup
          params[:search][:dealer_type] = "global_house"

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:contractors].count).to eq 0
          expect(res[:total_count]).to eq 0
        end
      end

      describe 'dealer' do
        let(:cbm_dealer) { FactoryBot.create(:cbm_dealer) }
        let(:cpac_dealer) { FactoryBot.create(:cpac_dealer) }

        before do
          eligibility = FactoryBot.create(:eligibility, contractor: contractor)
          FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)

          FactoryBot.create(:applied_dealer, contractor: contractor, dealer: cbm_dealer)
        end

        it '指定のdealerで取得できること' do
          params = default_params.dup
          params[:search][:dealer_id] = cbm_dealer.id

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:contractors].count).to eq 1
          expect(res[:total_count]).to eq 1
        end

        it '指定のdealerで取得ができないこと' do
          params = default_params.dup
          params[:search][:dealer_type] = cpac_dealer.id

          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:contractors].count).to eq 0
          expect(res[:total_count]).to eq 0
        end
      end
    end
  end
end
