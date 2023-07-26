require 'rails_helper'

RSpec.describe Jv::ProjectRegistrationController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:project_manager) { FactoryBot.create(:project_manager) }

  describe '#create_project' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project: {
          project_code: "B0001",
          project_type: "detached_house",
          project_name: "project_name_1",
          project_manager_id: project_manager.id,
          project_value: 50000.0,
          project_limit: 40000.0,
          project_owner: "project_owner_1",
          start_ymd: "20211115",
          finish_ymd: "20211215",
          contract_registered_ymd: "20211130",
          delay_penalty_rate: 18,
        }
      }
    }

    describe '正常値' do
      let(:project) { Project.last }

      it "登録できること" do
        post :create_project, params: default_params

        expect(res[:success]).to eq true
        
        expect(project.project_code).to eq default_params[:project][:project_code]
        expect(project.project_type).to eq default_params[:project][:project_type]
        expect(project.project_name).to eq default_params[:project][:project_name]
        expect(project.project_manager_id).to eq default_params[:project][:project_manager_id]
        expect(project.project_value).to eq default_params[:project][:project_value]
        expect(project.project_limit).to eq default_params[:project][:project_limit]
        expect(project.project_owner).to eq default_params[:project][:project_owner]
        expect(project.start_ymd).to eq default_params[:project][:start_ymd]
        expect(project.finish_ymd).to eq default_params[:project][:finish_ymd]
        expect(project.contract_registered_ymd).to eq default_params[:project][:contract_registered_ymd]
        expect(project.opened?).to eq true

        expect(project.create_user).to eq auth_token.tokenable
        expect(project.update_user).to eq auth_token.tokenable
      end
    end

    describe '業務エラー' do
      let(:project) { Project.last }

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

        post :create_project, params: params

        expect(res[:success]).to eq false
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
        expect(Project.count).to eq 0
      end
    end

  end
end