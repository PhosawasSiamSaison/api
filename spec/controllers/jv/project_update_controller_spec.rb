require 'rails_helper'

RSpec.describe Jv::ProjectUpdateController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) } 
  let(:create_user_auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:update_user_auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:create_user) { create_user_auth_token.tokenable }
  let(:update_user) { update_user_auth_token.tokenable }
  let(:project_manager) { FactoryBot.create(:project_manager) } 
  
  describe "#project" do
    let(:project) { FactoryBot.create(:project) }
    
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(project.id).to eq default_params[:project_id]
    end
  end
  
  describe '#update_project' do
    let(:project) { 
        FactoryBot.create(:project, create_user: create_user, update_user: update_user)
    }

    let(:default_params) {
      {
        auth_token: update_user_auth_token.token,
        project_id: project.id,
        project: {
          project_code: "testB0002",
          project_type: "detached_house",
          project_name: "project_name_test_2",
          project_manager_id: project_manager.id,
          project_owner: "project_owner_test_2",
          start_ymd: "20221115",
          finish_ymd: "20221215",
          contract_registered_ymd: "20221130",
          status: "closed"
        }
      }
    }

    describe '正常値' do
      it "登録できること" do
        patch :update_project, params: default_params

        expect(res[:success]).to eq true
        project.reload

        expect(project.project_code).to eq default_params[:project][:project_code]
        expect(project.project_type).to eq default_params[:project][:project_type]
        expect(project.project_name).to eq default_params[:project][:project_name]
        expect(project.project_manager_id).to eq default_params[:project][:project_manager_id]
        expect(project.project_owner).to eq default_params[:project][:project_owner]
        expect(project.start_ymd).to eq default_params[:project][:start_ymd]
        expect(project.finish_ymd).to eq default_params[:project][:finish_ymd]
        expect(project.contract_registered_ymd).to eq default_params[:project][:contract_registered_ymd]
        expect(project.status).to eq default_params[:project][:status]

        expect(project.create_user).to eq create_user
        expect(project.update_user).to eq update_user
      end
    end

    describe '業務エラー' do
      it "エラーが返ること" do
        params = default_params.dup
        params[:project][:project_code] = ''
        params[:project][:project_type] = ''
        params[:project][:project_name] = ''
        params[:project][:project_manager_id] = nil
        params[:project][:start_ymd] = ''
        params[:project][:finish_ymd] = ''
        params[:project][:contract_registered_ymd] = ''
        params[:project][:status] = nil

        patch :update_project, params: params

        expect(res[:success]).to eq false
        project.reload

        expect(res[:errors]).to eq [
          "Project manager must exist", 
          "Project code can't be blank", 
          "Project type can't be blank", 
          "Project name can't be blank", 
          "Start ymd can't be blank", 
          "Start ymd is the wrong length (should be 8 characters)", 
          "Finish ymd can't be blank", 
          "Finish ymd is the wrong length (should be 8 characters)", 
          "Contract registered ymd can't be blank", 
          "Contract registered ymd is the wrong length (should be 8 characters)"
        ]
      end
    end
  end

  describe "#delete_project" do
    let(:project) { FactoryBot.create(:project) }
    
    let(:params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "削除できること" do
      delete :delete_project, params: params

      expect(res[:success]).to eq true
      project.reload
      expect(project.deleted).to eq 1   
    end
    
  end
  
end