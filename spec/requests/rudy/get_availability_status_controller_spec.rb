require 'rails_helper'

RSpec.describe Rudy::GetAvailabilityStatusController, type: :request do

  describe "#call" do
    let(:contractor) {
      FactoryBot.create(:contractor, approval_status: "qualified")
    }

    before do
      FactoryBot.create(:eligibility, :latest, contractor: contractor, limit_amount: 1000)
    end

    it "正常に取得できること" do
      params = {
        tax_id: contractor.tax_id
      }

      get rudy_get_availability_status_path, params: params, headers: headers
      expect(res[:result]).to eq "OK"
    end

    it "値が正しく取得できること" do
      params = {
        tax_id: contractor.tax_id
      }

      get rudy_get_availability_status_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      expect(res[:credit_limit]).to eq 1000
      expect(res[:used_amount]).to eq 0
      expect(res[:available_balance]).to eq 1000
      expect(res[:cashback_amount]).to eq 0
      expect(res[:availability_status]).to eq 'available'
    end
  end

  describe "demo" do
    it 'デモ用のトークンでデモ用レスポンスが返ること' do
      params = {
        tax_id: "1234567890111"
      }

      get rudy_get_availability_status_path, params: params, headers: demo_token_headers
      expect(res[:result]).to eq "OK"
    end
  end
end
