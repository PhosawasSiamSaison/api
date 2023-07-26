require 'rails_helper'

RSpec.describe ProjectManager::UserRegistrationController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }
  
  describe "#create_user" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_manager_user: {
          user_name: 'user_name_1',
          full_name: 'full_name_1',
          user_type: 'md',
          mobile_number: '00000000001',
          email: 'test@example.com',
          password: 'password'
        }
      }
    }

    describe "正常値" do
      let(:project_manager_user) { ProjectManagerUser.last }

      it "登録できること" do
        post :create_user, params: default_params

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

        post :create_user, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [
            "Password can't be blank",
            "User name can't be blank",
            "Full name can't be blank"
        ]
      end
    end
  end
  
end
