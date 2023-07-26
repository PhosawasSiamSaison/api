require 'rails_helper'

RSpec.describe "Jv::Users API", type: :request do
  before do
    @auth_token = FactoryBot.create(:auth_token, :jv)
  end

  it "正常な値を返すこと" do
    aggregate_failures do
      expect {
        post create_user_jv_user_registration_index_path, params: { auth_token: @auth_token.token,
                                                                    jv_user:    {
                                                                      user_name:     "created_user",
                                                                      full_name:     "created_user",
                                                                      mobile_number: "xxxxxxxxxxx",
                                                                      email:         "created_user@example.com",
                                                                      user_type:     "staff",
                                                                      password:      "password" } }
      }.to change { JvUser.count }.by(1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      get search_jv_user_list_index_path, params: { auth_token: @auth_token.token,
                                                    search:     { show_inactive: true },
                                                    page:       "1",
                                                    per_page:   "10" }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy
      created_user_id = json["jv_users"][1]["id"]

      get jv_user_jv_user_update_index_path, params: { auth_token: @auth_token.token,
                                                       jv_user_id: created_user_id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      patch update_user_jv_user_update_index_path, params: { auth_token: @auth_token.token,
                                                             jv_user:    {
                                                               id:            created_user_id,
                                                               user_name:     "updated_user",
                                                               full_name:     "updated_user",
                                                               mobile_number: "xxxxxxxxxxx",
                                                               email:         "updated_user@example.com",
                                                               user_type:     "staff",
                                                               password:      "password"
                                                             } }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy

      expect {
        delete delete_user_jv_user_update_index_path, params: { auth_token: @auth_token.token,
                                                                jv_user_id: created_user_id }
      }.to change { JvUser.count }.by(-1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be_truthy
    end
  end

  describe "PATCH /change_password" do
    it "正常な値を返すこと" do
      aggregate_failures do
        patch update_password_jv_change_password_index_path, params: { auth_token:       @auth_token.token,
                                                                       current_password: "password",
                                                                       new_password:     "NewPassword" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be_truthy
      end
    end
  end

  describe '権限チェック' do
    let(:login_user) { FactoryBot.create(:jv_user, :staff) }
    let(:auth_token) { FactoryBot.create(:auth_token, tokenable: login_user) }

    describe 'create_user' do
      it '権限エラーになること' do
        path = create_user_jv_user_registration_index_path
        params = {
          auth_token: auth_token.token,
          jv_user: {
            user_name:     "created_user",
            full_name:     "created_user",
            mobile_number: "",
            email:         "created_user@example.com",
            user_type:     "staff",
            password:      "password"
          }
        }

        post path, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end

    describe 'update_user' do
      it '権限エラーになること' do
        path = update_user_jv_user_update_index_path
        params = { auth_token: auth_token.token }

        patch path, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end

    describe 'delete_user' do
      it '権限エラーになること' do
        path = delete_user_jv_user_update_index_path
        params = { auth_token: auth_token.token }

        delete path, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end
  end
end
