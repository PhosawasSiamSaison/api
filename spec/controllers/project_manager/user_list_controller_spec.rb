require 'rails_helper'

RSpec.describe ProjectManager::UserListController, type: :controller do
  describe "#create_user" do
    let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }
    let(:project_manager_user) { auth_token.tokenable } 

    let(:default_params) {
      {
        auth_token: auth_token.token
      }
    }

    it "値が取得できること" do
      get :search, params: default_params

      expect(res[:success]).to eq true
      expect(res[:project_manager_users].first[:id]).to eq project_manager_user.project_manager.project_manager_users.first.id
    end
  end

end
