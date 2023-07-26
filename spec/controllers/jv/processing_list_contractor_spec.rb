require 'rails_helper'

RSpec.describe Jv::ProcessingListController, type: :controller do
  describe '#controctor_serach ' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
    let(:contractor) {
      FactoryBot.create(:contractor,
                        main_dealer:        dealer,
                        approval_status:    "processing")
    }

    describe '検索条件' do
      it 'search が文字列でもエラーにならないこと' do
        params = {
          auth_token: auth_token.token,
          page:       1,
          per_page:   3,
          search:     "{
                \"tax_id\": \"\",
                \"company_name\": \"\",
                \"dealer_id\": -1
            }"
        }
        get :search, params: params
        expect(res[:success]).to eq true
        expect(res[:contractors]).to eq []
        expect(res[:total_count]).to eq 0
      end

      it '検索条件なしでエラーにならないこと' do
        params = {
          auth_token: auth_token.token,
          page:       1,
          per_page:   3,
          search:     {}
        }
        get :search, params: params
        expect(res[:success]).to eq true
        expect(res[:total_count]).to eq 0
      end

      context 'Contractor 1件' do
        before do
          FactoryBot.create(:contractor, :processing, tax_id: '1234567890123')
        end

        it 'search が検索条件入 json でもエラーにならないこと' do
          params = {
            auth_token: auth_token.token,
            page:       1,
            per_page:   10,
            search:     {
              tax_id: "1234567890123"
            }
          }

          get :search, params: params
          expect(res[:success]).to eq true
          expect(res[:contractors].count).to eq 1
        end
      end
    end
  end
end
