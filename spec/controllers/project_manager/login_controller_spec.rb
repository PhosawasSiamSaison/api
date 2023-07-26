require 'rails_helper'

RSpec.describe ProjectManager::LoginController, type: :controller do

  describe "#login" do
    let(:project_manager_user) { FactoryBot.create(:project_manager_user) }

    let(:default_params) {
      {
        user_name: project_manager_user.user_name,
        password: 'password'
      }
    }

    describe "正しいパスワード" do
      it "ログインが成功すること" do
        post :login, params: default_params

        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(res[:auth_token]).not_to eq nil
      end
    end

    describe "不正なパスワード" do
      it "ログインが失敗すること" do
        params = default_params.dup
        params[:password] = 'invalid_password'

        post :login, params: params

        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["Your Username or Passcode was incorrect"]
      end
    end
  end

end
