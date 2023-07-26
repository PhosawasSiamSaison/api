require 'rails_helper'

RSpec.describe ProjectManager::ChangePasswordController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }

  describe "#update_password" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        current_password: "password",
        new_password: "newPassword"
      }
    }

    describe "正しいパスワード" do
      it "登録できること" do
        patch :update_password, params: default_params

        expect(res[:success]).to eq true
      end
    end

    describe "不正なパスワード" do
      it "エラーになること" do
        params = default_params.dup
        params[:current_password] = 'invalidPassword'

        patch :update_password, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["Current password is invalid"]
      end
    end
    
  end
  
end
