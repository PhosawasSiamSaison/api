require 'rails_helper'

RSpec.describe Contractor::LoginController, type: :controller do
  let(:contractor_user) { FactoryBot.create(:contractor_user, password: '123456') }
  let(:contractor) { contractor_user.contractor }

  before do
    FactoryBot.create(:system_setting, cbm_terms_of_service_version: 1)
    FactoryBot.create(:eligibility, contractor: contractor)
  end

  describe "login" do
    it "初回ログインが成功すること" do
      params = {
        user_name: contractor_user.user_name,
        password: '123456'
      }

      post :login, params: params
      expect(res[:success]).to eq true
      expect(res[:auth_token].present?).to eq true
    end

    it "不正パスワードでエラーが返ること" do
      params = {
        user_name: contractor_user.user_name,
        password: '098765'
      }

      post :login, params: params
      expect(res[:success]).to eq false
      expect(res[:errors]).to eq [I18n.t('error_message.login_error')]
    end
  end
end
