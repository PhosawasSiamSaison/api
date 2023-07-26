require 'rails_helper'

RSpec.describe CommonController, type: :controller do

  describe "GET #business_ymd" do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190101')
    end

    let(:auth_token) { FactoryBot.create(:auth_token, :jv).token }

    it "正常に取得ができること" do
      params = {
        auth_token: auth_token
      }

      get :business_ymd, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:business_ymd]).to eq BusinessDay.business_ymd
    end
  end

  describe "GET #types" do
    let(:auth_token) { FactoryBot.create(:auth_token, :jv).token }

    it "正常に取得ができること" do
      params = {
        auth_token: auth_token,
        type: 'jv_user.user_type'
      }

      get :types, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:types].first[:code]).to eq 'md'
      expect(res[:types].first[:label]).to eq 'MD/MGR'
    end

    it "ActiveRecordのenumを継承したモデルのラベルが正常に取得できること" do
      params = {
        auth_token: auth_token,
        type: 'dealer.dealer_type'
      }

      get :types, params: params
      expect(res[:success]).to eq true
      expect(res[:types].find{|type| type[:code] == 'cbm'}[:label]).to eq 'CBM'
    end
  end
end
