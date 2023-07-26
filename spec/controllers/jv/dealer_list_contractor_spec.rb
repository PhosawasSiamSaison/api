require 'rails_helper'

RSpec.describe Jv::DealerListController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv)}
  let(:jv_user) { auth_token.tokenable }

  describe '#search' do
    let(:dealer) { Dealer.first }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        search: {
          dealer_code: "",
          dealer_name: "",
          area_name: "",
          show_inactive: "true"
        },
        page: "1",
        per_page: "10"
      }
    }

    before do
      FactoryBot.create(:dealer)
    end

    describe '正常値' do
      it "取得できること" do
        get :search, params: default_params

        expect(res[:success]).to eq true

        expect(res[:dealers].count).to eq 1
        expect(res[:dealers].first[:id]).to eq dealer.id
      end
    end
  end
end
