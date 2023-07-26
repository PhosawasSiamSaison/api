require 'rails_helper'

RSpec.describe Contractor::ProjectListController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
  let(:contractor) { auth_token.tokenable.contractor } 

  describe "#search" do
    before do
      FactoryBot.create(:project_phase_site, contractor: contractor)
    end

    let(:default_params) {
      {
        auth_token: auth_token.token,
        search: {
          include_closed_project: true
        }
      }
    }

    it "値が取得できること" do
      get :search, params: default_params

      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res[:projects].first[:id]).to eq contractor.projects.first.id
    end
  end

end
