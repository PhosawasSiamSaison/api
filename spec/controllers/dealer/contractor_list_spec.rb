require 'rails_helper'

RSpec.describe Dealer::ContractorListController, type: :controller do

  describe '#controctor_serach ' do
    let(:auth_token) { FactoryBot.create(:auth_token, :dealer) }
    let(:dealer_user) { auth_token.tokenable }
    let(:dealer) { dealer_user.dealer }

    before do
      contractor1 = FactoryBot.create(:contractor)
      contractor2 = FactoryBot.create(:contractor)
      contractor3 = FactoryBot.create(:contractor)

      eligibility1 = FactoryBot.create(:eligibility, contractor: contractor1)
      eligibility2 = FactoryBot.create(:eligibility, contractor: contractor2)
      eligibility3 = FactoryBot.create(:eligibility, contractor: contractor3)

      FactoryBot.create(:dealer_limit, eligibility: eligibility1, dealer: dealer)
      FactoryBot.create(:dealer_limit, eligibility: eligibility2, dealer: dealer)
      FactoryBot.create(:dealer_limit, eligibility: eligibility3)
    end

    it 'ページングが正しいこと。DealerLimitを設定したContractorのみが取得されること' do
      params = {
        auth_token: auth_token.token,
        page: 1,
        per_page: 1,
        search: {}
      }

      get :search, params: params

      expect(res[:success]).to eq true
      expect(res[:total_count]).to eq 2
      expect(res[:contractors].count).to eq 1

    end
  end
end
