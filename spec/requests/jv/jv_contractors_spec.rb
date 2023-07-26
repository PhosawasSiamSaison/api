require 'rails_helper'

RSpec.describe "Jv::Contractors API", type: :request do
  before do
    @auth_token      = FactoryBot.create(:auth_token, :jv)
    @contractor      = FactoryBot.create(:contractor)
    @contractor_user = FactoryBot.create(:contractor_user, contractor: @contractor)
  end

  it "正常な値を返すこと" do
    aggregate_failures do
      patch update_notes_jv_contractor_detail_index_path, params: { auth_token:    @auth_token.token,
                                                                    contractor_id: @contractor.id,
                                                                    notes:         { notes: "sample_notes" } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy
    end
  end
end

