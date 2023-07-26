require 'rails_helper'

RSpec.describe Jv::LoginController, type: :controller do

  describe "POST #login" do
    let(:jv_user) { FactoryBot.create(:jv_user) }

    it "returns http success" do
      params = {
        user_name: jv_user.user_name,
        password: 'password'
      }

      post :login, params: params
      expect(response).to have_http_status(:success)
    end

    it "auth success" do
      params = {
        user_name: jv_user.user_name,
        password: 'password'
      }

      post :login, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
    end

    it "invalid password" do
      params = {
        user_name: jv_user.user_name,
        password: 'invalid-password'
      }

      post :login, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq false
      expect(res[:errors]).to eq ["Your Username or Passcode was incorrect"]
    end
  end

end
