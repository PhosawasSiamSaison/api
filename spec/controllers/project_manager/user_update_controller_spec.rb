require 'rails_helper'

RSpec.describe ProjectManager::UserUpdateController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }

  describe "#project_manager_user" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_manager_user_id: auth_token.tokenable.id
      }
    }

    it "値が取得できること" do
      get :project_manager_user, params: default_params
      
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:project_manager_user][:id]).to eq default_params[:project_manager_user_id]
    end
  end

  describe "#update_user" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_manager_user_id: auth_token.tokenable.id,
        project_manager_user: {
          user_name: 'user_name_1_update',
          full_name: 'full_name_1_update',
          user_type: 'md',
          mobile_number: '00000000001',
          email: 'test_update@example.com',
          password: 'Updatepassword'
        }
      }
    }

    describe "正常値" do
      let(:project_manager_user) { ProjectManagerUser.last }

      it "登録できること" do
        patch :update_user, params: default_params

        expect(res[:success]).to eq true
        expect(project_manager_user.user_name).to eq default_params[:project_manager_user][:user_name]
        expect(project_manager_user.full_name).to eq default_params[:project_manager_user][:full_name]
        expect(project_manager_user.user_type).to eq default_params[:project_manager_user][:user_type]
        expect(project_manager_user.mobile_number).to eq default_params[:project_manager_user][:mobile_number]
        expect(project_manager_user.email).to eq default_params[:project_manager_user][:email]
        expect(project_manager_user).to eq project_manager_user.authenticate(default_params[:project_manager_user][:password])
      end
    end

    describe "業務エラー" do
      it "エラーになること" do
        params = default_params.dup
        params[:project_manager_user][:user_name] = ''
        params[:project_manager_user][:full_name] = ''
        params[:project_manager_user][:password] = ''

        patch :update_user, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [
            "User name can't be blank",
            "Full name can't be blank"
        ]
      end
    end
  end

  describe "#delete_user" do
    before do
      FactoryBot.create(:project_manager_user, :staff, project_manager: auth_token.tokenable.project_manager)
    end

    let(:project_manager_user) { ProjectManagerUser.last }
    
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_manager_user_id: project_manager_user.id
      }
    }

    describe "削除するユーザーが自分以外のとき" do
      it "削除できること" do
        delete :delete_user, params: default_params

        expect(res[:success]).to eq true
      end
    end

    describe "削除するユーザーが自分のとき" do
      it "削除に失敗すること" do
        params = default_params.dup
        params[:project_manager_user_id] = auth_token.tokenable.id

        delete :delete_user, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["Can't delete own account"]
      end
    end
  end
  
end
