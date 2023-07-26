require 'rails_helper'

RSpec.describe ProjectManager::ProjectPhaseDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }
  let(:project_manager) { auth_token.tokenable.project_manager } 
  let(:project) { FactoryBot.create(:project, project_manager: project_manager) }
  let(:project_phase) { FactoryBot.create(:project_phase, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase) }

  before do
      FactoryBot.create(:business_day)
  end

  describe "#project_phase" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "値が取得できること" do
      get :project_phase, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:phase][:id]).to eq default_params[:project_phase_id]
    end
  end
  
  describe "#project_basic_information" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "値が取得できること" do
      get :project_basic_information, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:project][:project_code]).to eq project.project_code
      expect(res[:project][:project_name]).to eq project.project_name
    end
  end

  describe "#evidence_list" do
    before do
      params = {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
        evidence: {
          file_name: "test.png",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }

      post :upload_evidence, params: params
  
      expect(res[:success]).to eq true
    end

    let(:evidence) { ProjectPhaseEvidence.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id
      }
    }

    it "値が取得できること" do
      get :evidence_list, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:evidences].first[:id]).to eq project_phase.project_phase_evidences.first.id
    end
  end

  describe "#upload_evidence" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
        evidence: {
          file_name: "test.png",
          comment: "test_comment",
          file_data: sample_image_data_uri
        }
      }
    }

    describe "正常値" do
      let(:evidence) { ProjectPhaseEvidence.last }
      it "登録できること" do
        post :upload_evidence, params: default_params
    
        expect(res[:success]).to eq true
        expect(evidence.comment).to eq default_params[:evidence][:comment]
        expect(evidence.file.attached?).to eq true 
      end
    end
  end
  
  describe "#payment_detail" do
    let(:default_params) { 
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
      }
    }

    it "値が取得できること" do
      get :payment_detail, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:due_ymd]).to eq project_phase.due_ymd
      expect(res[:phase_value]).to eq project_phase.phase_value
    end
  end

  describe "#project_phase_site_list" do
    before do
      FactoryBot.create(:project_phase_site, project_phase: project_phase)
    end

    let(:default_params) { 
      {
        auth_token: auth_token.token,
        project_phase_id: project_phase.id,
      }
    }

    it "値が取得できること" do
      get :project_phase_site_list, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:sites].first[:id]).to eq project_phase.project_phase_sites.first.id
    end
  end
  
  describe "#project_phase_site" do    
    let(:default_params) { 
      {
        auth_token: auth_token.token,
        project_phase_site_id: project_phase_site.id,
      }
    }

    it "値が取得できること" do
      get :project_phase_site, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:site][:id]).to eq default_params[:project_phase_site_id]
    end
  end
end
