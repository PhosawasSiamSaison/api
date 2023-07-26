require 'rails_helper'

RSpec.describe Contractor::ResetPasswordController, type: :controller do
  before do
    FactoryBot.create(:contractor_user, user_name: '1000000000001')
  end

  let(:contractor_user) { ContractorUser.first }
  let(:contractor) { contractor_user.contractor }

  describe "#reset_password" do
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        user_name: contractor_user.user_name,
      }
    }

    it "正常値" do
      get :reset_password, params: default_params

      expect(res[:success]).to eq true
      expect(res[:result]).to eq 'send_sms'
    end

    it "不正なuser_name" do
      params = default_params.dup
      params[:user_name] = '123'

      get :reset_password, params: params

      expect(res[:success]).to eq true # エラーではないのでtrueが返る
      expect(res[:result]).to eq 'invalid'
    end

    it "ロックロジックのチェック" do
      params = default_params.dup
      params[:user_name] = '123'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      Timecop.travel(Time.zone.now + 301.second)

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      get :reset_password, params: params
      expect(res[:result]).to eq 'locked'

      Timecop.travel(Time.zone.now + 290.second)

      get :reset_password, params: params
      expect(res[:result]).to eq 'locked'

      Timecop.travel(Time.zone.now + 11.second)

      get :reset_password, params: params
      expect(res[:result]).to eq 'invalid'

      10.times.each do
        Timecop.travel(Time.zone.now + 76.second) # 76: 一定時間で入力してエラーにならない間隔
        get :reset_password, params: params
        expect(res[:result]).to eq 'invalid'
      end
    end
  end

  describe "#update_password" do
    before do
      FactoryBot.create(:auth_token, tokenable: contractor_user)
    end

    it '正常に更新できること' do
      params = {
        password: '111111',
        auth_token: contractor_user.auth_tokens.last.token
      }

      patch :update_password, params: params

      expect(res[:success]).to eq true
      expect(res[:new_auth_token]).to eq contractor_user.auth_tokens.last.token
      expect(res[:user_name]).to eq contractor_user.user_name
    end

    it '不正なパスワードでエラーが返ること' do
      params = {
        password: '1',
        auth_token: contractor_user.auth_tokens.last.token
      }

      patch :update_password, params: params

      expect(res[:success]).to eq false
      expect(res[:errors]).to eq ["Password is the wrong length (should be 6 characters)"]
    end
  end
end
