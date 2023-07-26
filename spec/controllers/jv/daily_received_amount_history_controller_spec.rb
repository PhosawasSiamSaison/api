require 'rails_helper'

RSpec.describe Jv::DailyReceivedAmountHistoryController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
  let(:default_params) {
    {
      auth_token: auth_token.token,
      search: {
        receive_ymd: "",
        tax_id: "",
        company_name: ""
      },
      page: "1",
      per_page: "10"
    }.dup
  }

  describe '#search' do
    describe 'レスポンス' do
      before do
        FactoryBot.create(:receive_amount_history)
      end

      it '正常に値が取得できること' do
        get :search, params: default_params
        expect(res[:success]).to eq true
        expect(res[:histories].count).to eq 1
        expect(res[:total_amount].present?).to eq true
        expect(res[:total_count].present?).to eq true
      end
    end

    describe 'total_amount' do
      before do
        FactoryBot.create(:receive_amount_history, receive_amount: 0.01)
        FactoryBot.create(:receive_amount_history, receive_amount: 0.02)
      end

      it 'total_amountが正しいこと' do
        get :search, params: default_params
        expect(res[:success]).to eq true
        expect(res[:total_amount]).to eq 0.03
      end
    end
  end

  describe 'download_csv' do
    before do
      FactoryBot.create(:receive_amount_history)
    end

    describe '正常値' do
      it "CSV取得が取得できること" do
        params = {
          auth_token: auth_token.token
        }

        get :download_csv, params: params
        expect(response.header["Content-Type"]).to eq "text/csv"
      end
    end
  end
end
