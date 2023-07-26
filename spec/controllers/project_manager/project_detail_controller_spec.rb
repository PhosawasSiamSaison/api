require 'rails_helper'

RSpec.describe ProjectManager::ProjectDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }
  let(:project_manager) { auth_token.tokenable.project_manager }
  let(:project) { FactoryBot.create(:project, project_manager: project_manager) }
  let(:project_phase) { FactoryBot.create(:project_phase, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase) }

  def parse_base64(image)
    base64_image  = image.sub(/^data:.*,/, '')
    decoded_image = Base64.urlsafe_decode64(base64_image)
    StringIO.new(decoded_image)
  end

  describe "#project" do
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
      expect(res[:project][:id]).to eq default_params[:project_id]
    end
  end

  describe "#search_photos" do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id,
        search: {
          contractor_id: project_phase_site.contractor.id,
          phase_id: project_phase.id
        }
      }
    }

    it "値が取得できること" do
      get :search_photos, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:photos].count).not_to eq 0
    end
  end

  describe "#project_info_phases" do
    before do
      FactoryBot.create(:project_phase, project: project)
    end

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_info_phases, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:phases].first[:id]).to eq auth_token.tokenable.project_manager.project_phases.first.id
    end
  end

  describe "#project_info_contractors" do
    before do
      project_phasse = FactoryBot.create(:project_phase, project: project)
      FactoryBot.create(:project_phase_site, project_phase: project_phase)
    end

    let(:project_phase_site) { ProjectPhaseSite.last }

    let(:default_params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_info_contractors, params: default_params

      expect(res[:success]).to eq true
      expect(res[:contractors].first[:id]).to eq auth_token.tokenable.project_manager.projects.find(project.id).contractors.first.id
    end
  end

  describe "#project_phase_list" do
    before do
      FactoryBot.create(:project_phase, project: project)
    end

    let(:params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_phase_list, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:phases].first[:id]).to eq auth_token.tokenable.project_manager.project_phases.first.id
    end
  end

  describe "#project_documents" do
    before do
      document = FactoryBot.create(:project_document, project: project)
      document.file.attach(io: parse_base64(sample_image_data_uri), filename: document.file_name)
    end

    let(:params) {
      {
        auth_token: auth_token.token,
        project_id: project.id
      }
    }

    it "値が取得できること" do
      get :project_documents, params: params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:documents].first[:id]).to eq auth_token.tokenable.project_manager.project_documents.first.id
    end
  end

end