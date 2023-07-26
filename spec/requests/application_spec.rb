require 'rails_helper'

RSpec.describe "Application", type: :request do
  describe '#auth_user' do
    let(:jv_user) { FactoryBot.create(:auth_token, :jv).tokenable }
    let(:dealer_user) { FactoryBot.create(:auth_token, :dealer).tokenable }
    let(:contractor_user) {
      FactoryBot.create(:contractor_user, create_user: jv_user, update_user: jv_user)
    }

    before do
      FactoryBot.create(:business_day)
      FactoryBot.create(:system_setting)
      FactoryBot.create(:auth_token, tokenable: contractor_user)
    end

    context '成功' do
      it 'jv_userでjvのapiが取得できること' do
        params = {
          auth_token: jv_user.auth_tokens.first.token,
          jv_user_id: jv_user.id
        }

        get jv_user_jv_user_update_index_path, params: params
        expect(res[:success]).to eq true
      end

      it 'dealer_userでdealerのapiが取得できること' do
        params = {
          auth_token: dealer_user.auth_tokens.first.token,
          dealer_user_id: dealer_user.id
        }

        get dealer_user_dealer_user_update_index_path, params: params
        expect(res[:success]).to eq true
      end

      it 'contractor_userでcontractorのapiが取得できること' do
        params = {
          auth_token: contractor_user.auth_tokens.first.token,
          contractor_user_id: contractor_user.id
        }

        get contractor_user_contractor_user_update_index_path, params: params
        expect(res[:success]).to eq true
      end

      it 'commonが取得できること' do
        params = {
          auth_token: jv_user.auth_tokens.first.token
        }

        get business_ymd_common_index_path, params: params
        expect(res[:success]).to eq true
      end
    end

    context '失敗' do
      it 'jvでdealerのapiが取得できないこと' do
        params = {
          auth_token: jv_user.auth_tokens.first.token
        }

        get dealer_user_dealer_user_update_index_path, params: params
        expect(res[:success]).to eq false
        expect(res[:error]).to eq 'auth_failed'
      end

      it 'dealer_userでcontractorのapiが取得できないこと' do
        params = {
          auth_token: dealer_user.auth_tokens.first.token
        }

        get contractor_user_contractor_user_update_index_path, params: params
        expect(res[:success]).to eq false
        expect(res[:error]).to eq 'auth_failed'
      end

      it 'contractor_userでjvのapiが取得できないこと' do
        params = {
          auth_token: contractor_user.auth_tokens.first.token
        }

        get jv_user_jv_user_update_index_path, params: params
        expect(res[:success]).to eq false
        expect(res[:error]).to eq 'auth_failed'
      end
    end
  end
end
