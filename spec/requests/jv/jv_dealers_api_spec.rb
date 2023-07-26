require 'rails_helper'

describe "Jv::Dealers API", type: :request do
  before do
    @auth_token  = FactoryBot.create(:auth_token, :jv)
    @jv_user     = FactoryBot.create(:jv_user)
    @area        = FactoryBot.build(:area)
    other_area   = FactoryBot.build(:area)
    @dealer      = FactoryBot.create(:dealer, area: @area)
    @dealer_user = FactoryBot.create(:dealer_user, dealer: @dealer, create_user: @jv_user, update_user: @jv_user)
    FactoryBot.create(:dealer, area: other_area)
    FactoryBot.create(:dealer, area: @area, status: :inactive)
  end

  it "responds successfully" do
    aggregate_failures do
      get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                      page:       "1",
                                                      per_page:   "2" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["dealers"].length).to eq 2

      get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                      search:     { show_inactive: true } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["dealers"].length).to eq 3

      dealer_id = json["dealers"][0]["id"]
      get dealer_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token,
                                                        dealer_id:  dealer_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["dealer"]["dealer_name"]).to eq @dealer.dealer_name

      expect {
        post create_dealer_jv_dealer_registration_index_path, params: {
          auth_token: @auth_token.token,
          dealer: {
            tax_id: "sample_tax_id",
            area_id:     @area.id,
            dealer_code: "sample_code",
            dealer_name: "sample_dealer",
            dealer_type: :cbm,
            en_dealer_name: "sample_dealer",
            status:      "active"
          }
        }
      }.to change { Dealer.count }.by(1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      patch update_dealer_jv_dealer_update_index_path, params: { auth_token: @auth_token.token,
                                                                 dealer:     { id:          dealer_id,
                                                                               tax_id:      "update_tax_id",
                                                                               area_id:     @area.id,
                                                                               dealer_code: "updated_code",
                                                                               dealer_name: "updated_dealer",
                                                                               status:      "active" } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      expect {
        post create_dealer_user_jv_dealer_detail_index_path, params: { auth_token:  @auth_token.token,
                                                                       dealer_user: {
                                                                         dealer_id:     dealer_id,
                                                                         user_name:     "created_user",
                                                                         full_name:     "created_user",
                                                                         mobile_number: "012345678",
                                                                         email:         "created_user@example.com",
                                                                         user_type:     "owner",
                                                                         password:      "password" } }
      }.to change { DealerUser.count }.by(1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      get dealer_users_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token,
                                                              dealer_id:  dealer_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["dealer_users"].length).to eq 2
      expect(json["dealer_users"][0]["id"]).to eq @dealer_user.id
      created_user_id = json["dealer_users"][1]["id"]

      get dealer_user_jv_dealer_detail_index_path, params: { auth_token:     @auth_token.token,
                                                             dealer_user_id: created_user_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      patch update_dealer_user_jv_dealer_detail_index_path, params: { auth_token:  @auth_token.token,
                                                                      dealer_user: {
                                                                        id:            created_user_id,
                                                                        user_name:     "updated_user",
                                                                        full_name:     "updated_user",
                                                                        mobile_number: "876543210",
                                                                        email:         "updated_user@example.com",
                                                                        user_type:     "osr" } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      expect {
        delete delete_dealer_user_jv_dealer_detail_index_path, params: { auth_token:     @auth_token.token,
                                                                         dealer_user_id: created_user_id }
      }.to change { DealerUser.count }.by(-1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy
    end
  end

  describe "DealerList #search" do
    context "with exist parameter" do
      it "responds successfully" do
        aggregate_failures do
          get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                          search:     { dealer_code: @dealer.dealer_code } }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealers"].length).to eq 1

          get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                          search:     { dealer_name: @dealer.dealer_name } }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealers"].length).to eq 1

          get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                          search:     { area_name: @area.area_name } }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealers"].length).to eq 1
        end
      end
    end

    context "without applicable dealer" do
      it "returns status only" do
        get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                        search:     { dealer_name: "Not Applicable Dealer" } }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["dealers"].length).to eq 0
      end
    end

    context "without applicable parameter" do
      it "returns active dealer" do
        get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                        search:     { invalid_parameter: "Invalid Parameter" } }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["dealers"].length).to eq 2
      end
    end

    context "not exist parameter" do
      it "returns active dealer" do
        aggregate_failures do
          get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealers"].length).to eq 2
        end
      end
    end

    context "with null character" do
      it "returns active dealer" do
        get search_jv_dealer_list_index_path, params: { auth_token: @auth_token.token,
                                                        search:     { dealer_name: "" } }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["dealers"].length).to eq 2
      end
    end
  end

  describe "DealerDetail #dealer" do
    context "not exist parameter" do
      it "returns empty" do
        aggregate_failures do
          get dealer_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token }
          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be_falsey
        end
      end
    end

    context "not exist dealer_id" do
      it "returns empty" do
        aggregate_failures do
          get dealer_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token,
                                                            dealer_id:  1 }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be_falsey
        end
      end
    end

    context "with empty string" do
      it "returns empty" do
        aggregate_failures do
          get dealer_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token,
                                                            dealer_id:  "" }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be_falsey
        end
      end
    end

    context "with invalid parameter" do
      it "returns empty" do
        aggregate_failures do
          get dealer_jv_dealer_detail_index_path, params: { auth_token:        @auth_token.token,
                                                            invalid_parameter: "Invalid Parameter" }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be_falsey
        end
      end
    end
  end

  describe "DealerDetail #dealer_users" do
    context "not exist parameter" do
      it "returns empty" do
        aggregate_failures do
          get dealer_users_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealer_users"]).to be_empty
        end
      end
    end

    context "not exist dealer_id" do
      it "returns empty" do
        aggregate_failures do
          get dealer_users_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token,
                                                                  dealer_id:  1 }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealer_users"]).to be_empty
        end
      end
    end

    context "with empty string" do
      it "returns empty" do
        aggregate_failures do
          get dealer_users_jv_dealer_detail_index_path, params: { auth_token: @auth_token.token,
                                                                  dealer_id:  "" }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealer_users"]).to be_empty
        end
      end
    end

    context "with invalid parameter" do
      it "returns empty" do
        aggregate_failures do
          get dealer_users_jv_dealer_detail_index_path, params: { auth_token:        @auth_token.token,
                                                                  invalid_parameter: "Invalid Parameter" }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["dealer_users"]).to be_empty
        end
      end
    end
  end
end
