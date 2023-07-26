require 'rails_helper'

RSpec.describe Rudy::VerifyAccountController, type: :request do

  describe "#call" do
    let(:contractor_user) { FactoryBot.create(:contractor_user) }
    let(:contractor) { contractor_user.contractor }
    let(:default_params) {
      {
        username: contractor_user.user_name,
        one_time_passcode: contractor_user.rudy_passcode,
      }
    }

    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:rudy_api_setting)
    end

    context '正常値' do
      it '正しくレスポンスが返ること' do
        post rudy_verify_account_path, params: default_params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq "OK"
        expect(res[:auth_token]).to eq contractor_user.rudy_auth_token

        expect(contractor_user.rudy_passcode).to eq nil
      end

      context 'verify_modeがlogin_passcode' do
        it '正しくレスポンスが返ること' do
          params = default_params.dup

          params[:one_time_passcode] = '123456'
          post rudy_verify_account_path, params: params, headers: headers
          expect(res[:result]).to eq "OK"
        end
      end
    end

    context '異常値' do
      it 'contractor_unavailable' do
        contractor.inactive!

        post rudy_verify_account_path, params: default_params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq 'contractor_unavailable'
      end

      it 'invalid_user' do
        params = default_params.dup
        params[:username] = '9999999999999'

        post rudy_verify_account_path, params: params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq 'invalid_user'
      end

      it 'invalid_passcode' do
        params = default_params.dup

        params[:one_time_passcode] = ''
        post rudy_verify_account_path, params: params, headers: headers
        contractor_user.reload
        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq 'invalid_passcode'

        params[:one_time_passcode] = '1'
        post rudy_verify_account_path, params: params, headers: headers
        contractor_user.reload
        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq 'invalid_passcode'
      end

      it 'expired_passcode' do
        contractor_user.update!(rudy_passcode_created_at: Time.zone.now - 61.minutes)

        post rudy_verify_account_path, params: default_params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq 'expired_passcode'
      end

      context 'verify_modeがlogin_passcode' do
        it 'invalid_passcode' do
          params = default_params.dup

          params[:one_time_passcode] = ''
          post rudy_verify_account_path, params: params, headers: headers
          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq 'invalid_passcode'

          params[:one_time_passcode] = '1'
          post rudy_verify_account_path, params: params, headers: headers
          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq 'invalid_passcode'
        end
      end
    end
  end

  describe "demo" do
    it 'デモ用のトークンでデモ用レスポンスが返ること' do
      params = {
        username: 'user1'
      }

      post rudy_verify_account_path, params: params, headers: demo_token_headers
      expect(res[:result]).to eq "OK"
    end
  end
end
