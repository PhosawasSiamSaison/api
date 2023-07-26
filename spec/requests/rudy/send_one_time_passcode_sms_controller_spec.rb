require 'rails_helper'

RSpec.describe Rudy::SendOneTimePasscodeSmsController, type: :request do

  describe "#call" do
    let(:contractor_user) { FactoryBot.create(:contractor_user) }

    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:rudy_api_setting)
    end

    context '認証済み' do
      it "SMSが作成されること" do
        params = {
          username: contractor_user.user_name,
        }

        post rudy_send_one_time_passcode_sms_path, params: params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq 'OK'

        sms = SmsSpool.first
        expect(sms.present?).to eq true
        expect(sms.message_type).to eq 'send_one_time_passcode'
        expect(sms.message_body.include?(contractor_user.rudy_passcode)).to eq true
        expect(contractor_user.rudy_passcode_created_at.present?).to eq true
      end

      it "invalid_user エラーが帰ること" do
        params = {
          username: 'hoge',
        }

        post rudy_send_one_time_passcode_sms_path, params: params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'invalid_user'
      end

      it "contractor_unavailable エラーが帰ること" do
        contractor_user.contractor.inactive!

        params = {
          username: contractor_user.user_name,
        }

        post rudy_send_one_time_passcode_sms_path, params: params, headers: headers
        contractor_user.reload

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'contractor_unavailable'
      end
    end

    context 'verify_modeがlogin_passcode' do
      before do
        SystemSetting.login_passcode!
      end

      it "エラーが返ること" do
        params = {
          username: contractor_user.user_name,
        }

        post rudy_send_one_time_passcode_sms_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'otp_unavailable'
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
