require 'rails_helper'

RSpec.describe Contractor::PdpaListController, type: :controller do
  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day)
  end

  describe '#pdpa_list' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
      }
    }

    before do
      FactoryBot.create(:pdpa_version, version: 3, file_url: "hoge")

      contractor_user.create_latest_pdpa_agreement!
    end

    it '正常に取得できること' do
      post :pdpa_list, params: default_params

      expect(res[:success]).to eq true

      pdpa_list = res[:pdpa_list]

      pdpa = pdpa_list.first
      expect(pdpa[:id].present?).to eq true
      expect(pdpa[:file_url]).to eq "hoge"
      expect(pdpa[:version]).to eq 3
      expect(pdpa[:agreed_at].present?).to eq true
    end
  end
end
