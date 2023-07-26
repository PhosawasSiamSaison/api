require 'rails_helper'

RSpec.describe "Contractor::EvidenceOfPayment", type: :request do
  before do
    @auth_token    = FactoryBot.create(:auth_token, :contractor)
    @payment_image = sample_image_data_uri
    FactoryBot.create(:system_setting)
  end

  context "正常な値" do
    it "正常な値を返すこと" do
      aggregate_failures do
        post upload_contractor_evidence_of_payment_index_path, params: { auth_token:    @auth_token.token,
                                                                         payment_image: @payment_image }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be_truthy

        get evidence_list_contractor_evidence_of_payment_index_path, params: { auth_token: @auth_token.token }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be_truthy
        expect(json["evidences"].length).to eq 1
      end
    end

    context "アップロード画像が存在しない場合" do
      it "空の配列を返すこと" do
        get evidence_list_contractor_evidence_of_payment_index_path, params: { auth_token: @auth_token.token }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be_truthy
        expect(json["evidences"].length).to eq 0
      end
    end
  end

  context "不正な値" do
    describe "POST /upload" do
      context "payment_imageパラメータを送らない場合" do
        it "エラーになること" do
          post upload_contractor_evidence_of_payment_index_path, params: { auth_token:    @auth_token.token }

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be_falsy
          expect(json["errors"]).to eq ["invalid_payment_image"]
        end
      end
    end
  end
end
