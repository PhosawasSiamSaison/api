require 'rails_helper'

RSpec.describe ProjectManager::CommonController, type: :controller do
  let(:project_manager_user) { FactoryBot.create(:project_manager_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: project_manager_user) }

  describe "#header_info" do
    before do
      FactoryBot.create(:business_day)
    end

    let(:default_params) {
      {
        auth_token: auth_token.token
      }
    }

    it "値が取得ができること" do
      get :header_info, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:login_user][:id]).to eq project_manager_user.id
      expect(res[:login_user][:user_name]).to eq project_manager_user.user_name
      expect(res[:login_user][:full_name]).to eq project_manager_user.full_name
      expect(res[:business_ymd]).to eq BusinessDay.first.business_ymd
    end
  end

end
