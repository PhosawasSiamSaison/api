require 'rails_helper'

RSpec.describe Contractor::TermsOfServiceController, type: :controller do
  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user) }

  describe '#terms_of_service_version' do
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

    before do
      FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
    end

    it '規約同意バージョンが正しく取得できること' do
      params = {
        auth_token: auth_token.token
      }

      get :terms_of_service_versions, params: params
      expect(res[:success]).to eq true

      terms_of_service_versions = res[:terms_of_service_versions].first
      expect(terms_of_service_versions.count).to eq 1

      terms_of_service_version = terms_of_service_versions
      expect(terms_of_service_version[:type][:code]).to eq "cbm"
      expect(terms_of_service_version[:type][:label]).to eq "CBM"
    end
  end

  describe '#agreed' do
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        terms_of_service: {
          type: :cbm,
          version: 99
        }
      }
    }

    before do
      FactoryBot.create(:system_setting, cbm_terms_of_service_version: 99)
      FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
    end

    it '規約が正しく同意されること' do
      expect(contractor_user.require_agree_terms_of_service_types.count).to eq 1
      expect(contractor_user.require_agree_terms_of_service_types.first).to eq :cbm

      post :agreed, params: default_params
      expect(res[:success]).to eq true
      expect(res[:require_terms_of_service_versions]).to eq []
    end

    it '規約の同意バージョンが古い場合に正しいエラーが返ること' do
      expect(contractor_user.require_agree_terms_of_service_types.count).to eq 1
      expect(contractor_user.require_agree_terms_of_service_types.first).to eq :cbm

      params = default_params.dup
      params[:terms_of_service][:version] = 753

      post :agreed, params: params
      expect(res[:success]).to eq false
      expect(res[:error]).to eq I18n.t("error_message.updated_terms_of_service")
    end
  end
end
