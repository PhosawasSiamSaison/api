require 'rails_helper'

RSpec.describe Jv::PaymentForDealerListController, type: :controller do
  before do
    FactoryBot.create(:business_day)
    FactoryBot.create(:system_setting)
  end

  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }

  describe '#search' do
    describe '対象のOrderの検証' do
      let(:dealer) { FactoryBot.create(:dealer) }
      let(:order) { Order.first }
      let(:default_params) {
        {
          auth_token: auth_token.token,
          input_ymd: '20201001',
          dealer_id: nil,
        }
      }

      before do
        FactoryBot.create(:order, dealer: dealer, input_ymd: '20201001')
      end

      it '対象のオーダー１件あり' do
        get :search, params: default_params
        expect(res[:success]).to eq true
        expect(res[:dealers].count).to eq 1
      end

      it 'input_ymdの条件で絞られる事' do
        params = default_params.dup
        params[:input_ymd] = '20201002'

        get :search, params: params
        expect(res[:success]).to eq true
        expect(res[:dealers].count).to eq 0
      end

      context 'キャンセルあり' do
        before do
          order.update!(canceled_at: Time.now)
        end

        it 'キャンセル分が取得されない事' do
          get :search, params: default_params
          expect(res[:success]).to eq true
          expect(res[:dealers].count).to eq 0
        end
      end

      context 'input_ymdが異なるオーダーあり' do
        before do
          FactoryBot.create(:order, dealer: dealer, input_ymd: '20201002')
        end

        it 'countが一致する事' do
          get :search, params: default_params
          expect(res[:success]).to eq true
          expect(res[:dealers].count).to eq 1
          expect(res[:dealers].first[:order_count]).to eq 1
        end
      end

      context 'リスケオーダーあり' do
        before do
          payment = FactoryBot.create(:payment)
          FactoryBot.create(:installment, order: order, payment: payment, principal: 1000)

          contractor_id = order.contractor_id
          late_charge_ymd = '20211001'
          order_ids = [order.id]
          reschedule_order_count = 2
          fee_order_count = 3
          no_interest = false
          set_credit_limit_to_zero = false
          rescheduled_user = nil

          RescheduleOrders.new.call(contractor_id, late_charge_ymd, order_ids,
            reschedule_order_count, fee_order_count, no_interest, set_credit_limit_to_zero,
            rescheduled_user)
        end

        it '新しいオーダーが取得されない事' do
          get :search, params: default_params
          expect(res[:success]).to eq true
          expect(res[:dealers].count).to eq 1
          dealer = Dealer.find(res[:dealers].first[:dealer_id])
          expect(dealer.orders.count).to eq 1
          order = dealer.orders.first
          expect(order.rescheduled?).to eq true
        end
      end

      context 'Second Dealerのオーダーあり' do
        let(:second_dealer) { FactoryBot.create(:dealer) }

        before do
          order.second_dealer = second_dealer
          order.second_dealer_amount = 1
          order.save!
        end

        it 'Second Dealerが取得されること' do
          get :search, params: default_params

          expect(res[:success]).to eq true
          expect(res[:dealers].count).to eq 2
        end

        it '指定したSecond Dealerが取得されること' do
          params = default_params.dup
          params[:dealer_id] = second_dealer.id
          get :search, params: params

          expect(res[:success]).to eq true
          expect(res[:dealers].count).to eq 1
          expect(res[:dealers].first[:dealer_id]).to eq second_dealer.id
        end
      end
    end
  end
end
