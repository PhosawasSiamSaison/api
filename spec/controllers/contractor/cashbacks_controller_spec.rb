require 'rails_helper'

RSpec.describe Contractor::CashbacksController, type: :controller do
  before do
    FactoryBot.create(:system_setting)
  end

  describe '#cashbacks ' do
    let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
    let(:contractor) { auth_token.tokenable.contractor }

    it 'returns http success' do
      params = {
          auth_token: auth_token.token,
          page:       1,
          per_page:   1
      }
      get :cashback_info, params: params
      expect(response).to have_http_status(:success)
    end

    describe 'レコードなし' do
      it '0件で取得できること' do
        params = {
            auth_token: auth_token.token,
            page:       1,
            per_page:   3
        }

        get :cashback_info, params: params

        expect(res[:success]).to eq true
        expect(res[:cashback_histories]).to eq []
        expect(res[:total_count]).to eq 0
      end
    end

    describe 'レコード1件' do
      before do
        FactoryBot.create(:cashback_history,
                          contractor: contractor)
      end
      it '1件で取得できること' do
        params = {
            auth_token: auth_token.token,
            page:       1,
            per_page:   1
        }

        get :cashback_info, params: params
        expect(res[:success]).to eq true
        expect(res[:cashback_histories].count).to eq 1
        expect(res[:total_count]).to eq 1
        expect(res[:cashback_histories][0][:cashback_amount].is_a? Float).to eq true
      end
    end

    describe 'レコード21件で 20件取得できること' do
      before do
        21.times.each_with_index do |index|
          FactoryBot.create(:cashback_history, contractor: contractor, order: nil, point_type: index % 2 === 0 ? 'gain' : 'use')
        end
      end

      it '20件で取得できるて、トータル件数は21件であること' do
        params = {
            auth_token: auth_token.token,
            page:       1,
            per_page:   20
        }

        get :cashback_info, params: params

        expect(res[:success]).to eq true
        expect(res[:cashback_histories].count).to eq 20
        expect(res[:total_count]).to eq 21
      end
    end
  end
end
