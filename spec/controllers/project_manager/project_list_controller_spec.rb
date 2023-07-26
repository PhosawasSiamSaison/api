require 'rails_helper'

RSpec.describe ProjectManager::ProjectListController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :project_manager) }
  let(:project_manager) { auth_token.tokenable.project_manager }
  let(:project) { FactoryBot.create(:project, project_manager: project_manager) }
  let(:project_phase) { FactoryBot.create(:project_phase, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase) }

  describe '#search' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        search: {
          project_code: 'B0001',
          finish_date: {
              from_ymd: '20210101',
              to_ymd: '20211231'
          },
          tax_id: project_phase_site.contractor.tax_id,
          contractor_company_name: project_phase_site.contractor.en_company_name,
          include_closed_project: true
        },
        page: 1,
        per_page: 10
      }
    }

    describe '正常値' do
      it "値が取得できること" do
        request.env["CONTENT_TYPE"] = 'application/json'
        get :search, params: default_params

        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(res[:projects].first[:id]).to eq auth_token.tokenable.project_manager.projects.first.id
      end
    end
  end

end
