require 'rails_helper'

RSpec.describe Dealer::ContractorDetailController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :dealer) }
  let(:dealer) { auth_token.tokenable.dealer }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

  before do
    FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: dealer)
  end

  describe 'GET basic_information' do
    it "レスポンスが正常に返ること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :basic_information, params: params

      expect(res[:success]).to eq true
    end
  end

  describe 'GET contractor_users' do
    before do
      FactoryBot.create(:dealer_user, dealer: dealer)
    end

    it "レスポンスが正常に返ること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :contractor_users, params: params

      expect(res[:success]).to eq true
    end
  end

  describe 'GET status' do
    it "レスポンスが正常に返ること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :status, params: params

      expect(res[:success]).to eq true
    end
  end

  describe 'GET current_eligibility' do
    it "レスポンスが正常に返ること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :current_eligibility, params: params

      expect(res[:success]).to eq true
    end
  end

  describe 'GET more_information ' do
    it "レスポンスが正常に返ること" do
      params = {
        contractor_id: contractor.id,
        auth_token:    auth_token.token
      }

      get :more_information, params: params

      expect(res[:success]).to eq true
    end
  end
end
