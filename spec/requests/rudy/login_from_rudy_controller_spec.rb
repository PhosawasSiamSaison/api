require 'rails_helper'

RSpec.describe Rudy::LoginFromRudyController, type: :request do
  before do
    FactoryBot.create(:system_setting)
  end

  describe "#call" do
    context '成功' do
      before do
        FactoryBot.create(:contractor_user, user_name: "0000000000001", password: "123456")
      end

      it "認証が成功すること" do
        params = {
          username: "0000000000001",
          passcode: "123456"
        }

        post rudy_auth_user_passcode_path, params: params, headers: headers
        expect(response).to have_http_status(:success)

        expect(res[:result]).to eq 'OK'
      end
    end

    context '存在しないuser_nameを指定' do
      before do
        FactoryBot.create(:contractor_user, user_name: "0000000000009", password: "123456")
      end

      it "invalid_userエラーが返ること" do
        params = {
          username: "0000000000001",
          passcode: "123456"
        }

        post rudy_auth_user_passcode_path, params: params, headers: headers
        expect(response).to have_http_status(:success)

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'invalid_user'
      end
    end

    context '不正なパスワードを指定' do
      before do
        FactoryBot.create(:contractor_user, user_name: "0000000000001", password: "123456")
      end

      it "invalid_userエラーが返ること" do
        params = {
          username: "0000000000001",
          passcode: "234567"
        }

        post rudy_auth_user_passcode_path, params: params, headers: headers
        expect(response).to have_http_status(:success)

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'invalid_passcode'
      end
    end
  end

  private
  def headers
    bearer_key = JvService::Application.config.try(:rudy_api_auth_key)
    {
      'Authorization': "Bearer #{bearer_key}"
    }
  end
end
