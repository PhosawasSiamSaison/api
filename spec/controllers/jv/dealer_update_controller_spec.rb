require 'rails_helper'

RSpec.describe Jv::DealerUpdateController, type: :controller do
  let(:area) { FactoryBot.create(:area)}
  let(:area2) { FactoryBot.create(:area)}
  let(:create_user_auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:update_user_auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:create_user) { create_user_auth_token.tokenable }
  let(:update_user) { update_user_auth_token.tokenable }

  describe '#update_dealer' do
    let(:dealer) { FactoryBot.create(:dealer, tax_id: '1000000000001', area: area, dealer_code: 1,
      dealer_name: 'test dealer', status: 'active', bank_account: 'test bank', address: 'test address',
      create_user: create_user, update_user: create_user) }

    let(:default_params) {
      {
        auth_token: update_user_auth_token.token,
        dealer: {
          id: dealer.id,
          tax_id: "1000000000002",
          area_id: area2.id,
          dealer_code: "2",
          dealer_name: "test dealer 2",
          status: "inactive",
          bank_account: "test bank 2",
          address: "test address 2"
        }
      }
    }

    describe '正常値' do
      it "登録できること" do
        post :update_dealer, params: default_params

        expect(res[:success]).to eq true
        dealer.reload

        expect(dealer.tax_id).to eq       default_params[:dealer][:tax_id]
        expect(dealer.area.id).to eq      default_params[:dealer][:area_id]
        expect(dealer.dealer_code).to eq  default_params[:dealer][:dealer_code]
        expect(dealer.dealer_name).to eq  default_params[:dealer][:dealer_name]
        expect(dealer.status).to eq       default_params[:dealer][:status]
        expect(dealer.bank_account).to eq default_params[:dealer][:bank_account]
        expect(dealer.address).to eq      default_params[:dealer][:address]

        expect(dealer.create_user).to eq create_user
        expect(dealer.update_user).to eq update_user
      end
    end

    describe '業務エラー' do
      before do
        FactoryBot.create(:dealer)
      end

      it "エラーが返ること" do
        params = default_params.dup
        params[:dealer][:dealer_name] = ''

        post :update_dealer, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["Dealer name can't be blank"]
        expect(Dealer.last.lock_version).to eq 0
      end
    end
  end
end
