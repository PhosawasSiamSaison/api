require 'rails_helper'

RSpec.describe Dealer::HomeController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :dealer) }
  let(:dealer_user) { auth_token.tokenable }
  let(:dealer) { auth_token.tokenable.dealer }

  describe '#graph1' do
    describe '正常値' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        eligibility = FactoryBot.create(:eligibility, contractor: contractor)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer)
      end

      it '正常に取得ができること' do
        params = {
          auth_token: auth_token.token
        }

        get :graph1, params: params
        expect(res[:success]).to eq true
        
        expect(res[:credit_limit]).to be > 0
        expect(res[:available_balance]).to be > 0
        expect(res[:used_amount]).to eq 0

        expect(res[:contractor_count]).to eq 1
        expect(res[:in_use_count]).to eq 0
        expect(res[:not_in_use_count]).to eq 0
        expect(res[:not_use_count]).to eq 1

        expect(res[:order_count]).to eq 0
        expect(res[:inputed_ymd_count]).to eq 0
        expect(res[:not_input_ymd_count]).to eq 0
      end
    end

    describe 'contractor graph' do
      context 'in use' do
        before do
          contractor1 = FactoryBot.create(:contractor)
          contractor2 = FactoryBot.create(:contractor)
          contractor3 = FactoryBot.create(:contractor)
          FactoryBot.create(:order, contractor: contractor1, paid_up_ymd: nil)
          FactoryBot.create(:order, contractor: contractor1, paid_up_ymd: '20190101')
          FactoryBot.create(:order, contractor: contractor2, paid_up_ymd: nil)
          FactoryBot.create(:order, contractor: contractor3, paid_up_ymd: nil)
          FactoryBot.create(:order, contractor: contractor3, paid_up_ymd: '20190101')
          eligibility1 = FactoryBot.create(:eligibility, contractor: contractor1)
          eligibility2 = FactoryBot.create(:eligibility, contractor: contractor2)
          eligibility3 = FactoryBot.create(:eligibility, contractor: contractor3)
          FactoryBot.create(:dealer_limit, eligibility: eligibility1, dealer: dealer)
          FactoryBot.create(:dealer_limit, eligibility: eligibility2, dealer: dealer)
          FactoryBot.create(:dealer_limit, eligibility: eligibility3, dealer: dealer)

          contractor4 = FactoryBot.create(:contractor)
          contractor5 = FactoryBot.create(:contractor)
          FactoryBot.create(:order, contractor: contractor4, paid_up_ymd: '20190101')
          FactoryBot.create(:order, contractor: contractor5, paid_up_ymd: '20190101')
          eligibility4 = FactoryBot.create(:eligibility, contractor: contractor4)
          eligibility5 = FactoryBot.create(:eligibility, contractor: contractor5)
          FactoryBot.create(:dealer_limit, eligibility: eligibility4, dealer: dealer)
          FactoryBot.create(:dealer_limit, eligibility: eligibility5, dealer: dealer)

          contractor6 = FactoryBot.create(:contractor)
          eligibility6 = FactoryBot.create(:eligibility, contractor: contractor6)
          FactoryBot.create(:dealer_limit, eligibility: eligibility6, dealer: dealer)
        end

        it '正しい値が取得できること' do
          params = {
            auth_token: auth_token.token
          }

          get :graph1, params: params
          expect(res[:success]).to eq true

          expect(res[:contractor_count]).to eq 6
          expect(res[:in_use_count]).to eq 3
          expect(res[:not_in_use_count]).to eq 2
          expect(res[:not_use_count]).to eq 1
        end
      end
    end

    describe 'input date graph' do
      context '他のDealer' do
        before do
          contractor = FactoryBot.create(:contractor)
          FactoryBot.create(:order, contractor: contractor)
        end

        it '正しい値が取得できること' do
          params = {
            auth_token: auth_token.token
          }

          get :graph1, params: params
          expect(res[:success]).to eq true

          expect(res[:order_count]).to eq 0
          expect(res[:inputed_ymd_count]).to eq 0
          expect(res[:not_input_ymd_count]).to eq 0
        end
      end

      context 'inputed date' do
        before do
          FactoryBot.create(:order, :inputed_date, dealer: dealer)
        end

        it '正しい値が取得できること' do
          params = {
            auth_token: auth_token.token
          }

          get :graph1, params: params
          expect(res[:success]).to eq true

          expect(res[:order_count]).to eq 1
          expect(res[:inputed_ymd_count]).to eq 1
          expect(res[:not_input_ymd_count]).to eq 0
        end
      end

      context 'not inputed date' do
        before do
          FactoryBot.create(:order, dealer: dealer)
        end

        it '正しい値が取得できること' do
          params = {
            auth_token: auth_token.token
          }

          get :graph1, params: params
          expect(res[:success]).to eq true

          expect(res[:order_count]).to eq 1
          expect(res[:inputed_ymd_count]).to eq 0
          expect(res[:not_input_ymd_count]).to eq 1
        end
      end

      context 'cancel order' do
        before do
          FactoryBot.create(:order, :canceled, dealer: dealer)
        end

        it '正しい値が取得できること' do
          params = {
            auth_token: auth_token.token
          }

          get :graph1, params: params
          expect(res[:success]).to eq true

          expect(res[:order_count]).to eq 0
          expect(res[:inputed_ymd_count]).to eq 0
          expect(res[:not_input_ymd_count]).to eq 0
        end
      end
    end

    describe 'inactiveなcontractor' do
      let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer, status: 'inactive') }

      before do
        FactoryBot.create(:eligibility, :latest, contractor: contractor)
      end

      it '正常に取得ができること' do
        params = {
          auth_token: auth_token.token
        }

        get :graph1, params: params
        expect(res[:success]).to eq true

        expect(res[:credit_limit]).to eq 0
        expect(res[:available_balance]).to eq 0
        expect(res[:used_amount]).to eq 0
        expect(res[:contractor_count]).to eq 0
        expect(res[:in_use_count]).to eq 0
        expect(res[:not_in_use_count]).to eq 0
      end
    end
  end

  describe '#graph2 ' do
    describe '正常値' do
      before do
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201812')
      end

      it '正常に取得ができること' do
        params = {
          auth_token: auth_token.token
        }

        get :graph2, params: params
        expect(res[:success]).to eq true
        expect(res[:purchase_data].count).to eq 1

        purchase_data = res[:purchase_data].first
        expect(purchase_data[:month]).to eq '201812'
        expect(purchase_data[:purchase_amount]).to eq 1000.0
        expect(purchase_data[:order_count]).to eq 1
      end
    end

    describe '複数のデータ' do
      before do
        # 13件のデータ
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201712')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201801')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201802')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201803')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201804')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201805')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201806')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201807')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201808')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201809')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201810')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201811')
        FactoryBot.create(:dealer_purchase_of_month, dealer: dealer, month: '201812')
      end

      it '正常に取得ができること' do
        params = {
          auth_token: auth_token.token
        }

        get :graph2, params: params
        expect(res[:success]).to eq true
        # 直近の12件
        expect(res[:purchase_data].count).to eq 12
        # 古い日付が先頭
        expect(res[:purchase_data].first[:month]).to eq '201801'
        expect(res[:purchase_data].last[:month]).to eq  '201812'
      end
    end
  end
end
