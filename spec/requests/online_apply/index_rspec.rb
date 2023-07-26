require 'rails_helper'

RSpec.describe 'OnlineApply::Index API', type: :request do
  describe 'send_validation_email' do
    context 'with valid parameters' do
      before do
        allow(SendMail).to receive(:send_online_apply_one_time_passcode)
      end

      it 'responds successfully' do
        params = { email: 'test@example.com' }
        expect{
          post online_apply_send_validation_email_path, params: params
        }.to change(OneTimePasscode, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be_truthy
        expect(json['token'].present?).to be_truthy

        expect(SendMail).to have_received(:send_online_apply_one_time_passcode).once
      end
    end

    context 'with invalid mail address' do
      it 'returns error message' do
        aggregate_failures do
          params = { email: 'example.com' }
          post online_apply_send_validation_email_path, params: params

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be_falsy
          expect(json['error']).to eq 'invalid_email'
        end
      end
    end
  end

  describe 'send_validation_sms' do
    context 'with valid parameters' do
      before do
        allow(SendMessage).to receive(:send_online_apply_one_time_passcode)
      end

      it 'responds successfully' do
        params = { phone_number: '0123456789' }
        expect{
          post online_apply_send_validation_sms_path, params: params
        }.to change(OneTimePasscode, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be_truthy
        expect(json['token'].present?).to be_truthy

        expect(SendMessage).to have_received(:send_online_apply_one_time_passcode).once
      end
    end

    context 'with invalid mail address' do
      it 'returns error message' do
        aggregate_failures do
          params = { phone_number: '012345678' } # 9文字
          post online_apply_send_validation_sms_path, params: params

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be_falsy
          expect(json['error']).to eq 'invalid_phone_number'

          params = { phone_number: '012345678912' } # 12文字
          post online_apply_send_validation_sms_path, params: params

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be_falsy
          expect(json['error']).to eq 'invalid_phone_number'
        end
      end
    end

    describe 'validate_passcode' do
      context 'after send_validation_email' do
        before do
          params = { email: 'test@example.com' }
          post online_apply_send_validation_email_path, params: params
          json = JSON.parse(response.body)
          @token = json['token']
          @passcode = OneTimePasscode.last.passcode
        end

        context 'with valid parameters' do
          it 'responds successfully' do
            params = { token: @token, passcode: @passcode }
            post online_apply_validate_passcode_path, params: params

            expect(response).to have_http_status(:success)
            json = JSON.parse(response.body)
            expect(json['success']).to be_truthy
          end
        end

        context 'with invalid token' do
          it 'returns error message' do
            params = { token: SecureRandom.urlsafe_base64, passcode: @passcode }
            post online_apply_validate_passcode_path, params: params

            expect(response).to have_http_status(:success)
            json = JSON.parse(response.body)
            expect(json['success']).to be_falsy
            expect(json['error']).to eq 'invalid_token'
          end
        end

        context 'with invalid token' do
          it 'returns error message' do
            params = { token: SecureRandom.urlsafe_base64, passcode: @passcode }
            post online_apply_validate_passcode_path, params: params

            expect(response).to have_http_status(:success)
            json = JSON.parse(response.body)
            expect(json['success']).to be_falsy
            expect(json['error']).to eq 'invalid_token'
          end
        end

        context 'with invalid passcode' do
          it 'returns error message' do
            params = { token: @token, passcode: 6.times.map { SecureRandom.random_number(10) }.join }
            post online_apply_validate_passcode_path, params: params

            expect(response).to have_http_status(:success)
            json = JSON.parse(response.body)
            expect(json['success']).to be_falsy
            expect(json['error']).to eq 'invalid_passcode'
          end
        end

        context 'when passcode is expired' do
          it 'returns error message' do
            Timecop.travel Time.zone.now + JvService::Application.config.try(:online_apply_validate_address_limit_minutes).minutes + 1.second

            params = { token: @token, passcode: @passcode }
            post online_apply_validate_passcode_path, params: params

            expect(response).to have_http_status(:success)
            json = JSON.parse(response.body)
            expect(json['success']).to be_falsy
            expect(json['error']).to eq 'passcode_expired'
          end
        end
      end
    end

    context 'after send_validation_sms' do
      before do
        params = { phone_number: '0123456789' }
        post online_apply_send_validation_sms_path, params: params
        json = JSON.parse(response.body)
        @token = json['token']
        @passcode = OneTimePasscode.last.passcode
      end

      context 'with valid parameters' do
        it 'responds successfully' do
          params = { token: @token, passcode: @passcode }
          post online_apply_validate_passcode_path, params: params

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json['success']).to be_truthy
        end
      end
    end
  end
end
