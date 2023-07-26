require 'rails_helper'

RSpec.describe "QrCodeForPaymentController", type: :request do
  before do
    FactoryBot.create(:system_setting)
  end

  describe "get qr_code" do
    let(:jv_token) { FactoryBot.create(:auth_token, :jv) }
    let(:contractor_token) { FactoryBot.create(:auth_token, :contractor) }
    let(:contractor) { contractor_token.tokenable.contractor }

    it '画像の取得が成功すること' do
      params = {
        auth_token: jv_token.token,
        contractor_id: contractor.id,
        qr_code_image: sample_image_data_uri,
      }

      post upload_qr_code_image_jv_contractor_detail_index_path, params: params
      expect(res[:success]).to eq true

      params = {
        auth_token: contractor_token.token,
      }

      get qr_code_contractor_qr_code_for_payment_index_path, params: params
      expect(res[:success]).to eq true
      expect(res[:qr_code_image_url].present?).to eq true
    end
  end
end
