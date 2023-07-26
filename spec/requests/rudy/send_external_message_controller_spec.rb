require 'rails_helper'

RSpec.describe Rudy::SendExternalMessageController, type: :request do

  describe "#call" do
    let(:contractor) { FactoryBot.create(:contractor) }
    let(:contractor_user1) { ContractorUser.first }
    let(:contractor_user2) { ContractorUser.second }

    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        username: contractor_user1.user_name,
        message: 'abc',
      }
    }

    before do
      FactoryBot.create(:system_setting)
      FactoryBot.create(:rudy_api_setting)

      FactoryBot.create(:contractor_user, contractor: contractor)
      FactoryBot.create(:contractor_user, contractor: contractor, user_type: :other)
    end

    describe '正常パターン' do
      it '指定のContractorUserに送信されること' do
        params = default_params.dup

        post rudy_send_external_message_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        expect(SmsSpool.all.count).to eq 1

        sms = SmsSpool.first
        expect(sms.present?).to eq true
        expect(sms.message_body).to eq 'abc'
        expect(sms.message_type).to eq 'external_message_from_rudy'
      end

      it 'SSAから送信' do
        params = default_params.dup

        post send_external_message_path, params: params, headers: ssa_headers

        expect(res[:result]).to eq 'OK'

        expect(SmsSpool.all.count).to eq 1

        sms = SmsSpool.first
        expect(sms.present?).to eq true
        expect(sms.message_body).to eq 'abc'
        expect(sms.message_type).to eq 'external_message_from_ssa'
      end

      it 'Contractor内の ContractorUserに送信されること' do
        params = default_params.dup
        params[:username] = nil

        post rudy_send_external_message_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        expect(SmsSpool.all.count).to eq 2
      end
    end

    describe 'エラーチェック' do
      it '不正なbearerでエラーになること' do
        params = default_params.dup

        post rudy_send_external_message_path, params: params, headers: ssa_headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'auth_failed'
      end

      it 'messageの文字数超過でエラー' do
        params = default_params.dup
        params[:message] = 'a' * 501

        post rudy_send_external_message_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'too_long_message'
      end

      it '不正なtax_id' do
        params = default_params.dup
        params[:tax_id] = '123'

        post rudy_send_external_message_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'contractor_not_found'
      end

      it '不正なusername' do
        params = default_params.dup
        params[:username] = '123'

        post rudy_send_external_message_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'invalid_user'
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

  def ssa_headers
    bearer_key = JvService::Application.config.try(:ssa_api_auth_key)
    {
      'Authorization': "Bearer #{bearer_key}"
    }
  end
end
