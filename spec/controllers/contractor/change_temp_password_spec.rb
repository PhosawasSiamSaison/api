require 'rails_helper'

RSpec.describe Contractor::ChangeTempPasswordController, type: :controller do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:eligibility, contractor: contractor)
  end

  let(:contractor_user) { FactoryBot.create(:contractor_user, password: '123456', temp_password: "123456") }
  let(:contractor) { contractor_user.contractor }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user) }

  describe '#update_password' do
    it '正常値' do
      params = {
        auth_token: auth_token.token,
        password: '111111'
      }

      post :update_password, params: params

      expect(res[:success]).to eq true
    end

    it '同じパスワードでエラー' do
      params = {
        auth_token: auth_token.token,
        password: '123456'
      }

      post :update_password, params: params

      expect(res[:success]).to eq false
      expect(res[:errors]).to eq ["You must register a password different from the current password"]
    end

    describe '規約バージョンの不一致' do
      let(:eligibility) { Eligibility.first }

      before do
        SystemSetting.update!(cbm_terms_of_service_version: 2)
        
        FactoryBot.create(:dealer_type_limit, eligibility: eligibility, dealer_type: :cbm)
        FactoryBot.create(:terms_of_service_version, contractor_user: contractor_user,
          dealer_type: :cbm, sub_dealer: false, version: 1)
      end

      it 'エラーが返ること' do
        params = {
          auth_token: auth_token.token,
          password: '123456'
        }

        post :update_password, params: params

        expect(res[:success]).to eq false
        expect(res[:error]).to eq I18n.t("error_message.updated_terms_of_service")
        expect(res[:updated_terms_of_service]).to eq true
      end
    end
  end
end
