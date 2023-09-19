require 'rails_helper'

RSpec.describe Jv::DealerRegistrationController, type: :controller do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:area) { FactoryBot.create(:area)}

  describe '#create_dealer' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        dealer: {
          tax_id: "1000000000001",
          area_id: area.id,
          dealer_code: "1",
          dealer_name: "test dealer",
          dealer_type: :cbm,
          en_dealer_name: "test en dealer",
          status: "active",
          bank_account: "test bank",
          address: "test address"
        }
      }
    }

    describe '正常値' do
      let(:dealer) { Dealer.last }
      before do
        FactoryBot.create(:business_day)
        FactoryBot.create(:system_setting)
      end

      it "登録できること" do
        post :create_dealer, params: default_params

        expect(res[:success]).to eq true

        expect(dealer.tax_id).to eq default_params[:dealer][:tax_id]
        expect(dealer.area.id).to eq default_params[:dealer][:area_id]
        expect(dealer.dealer_code).to eq default_params[:dealer][:dealer_code]
        expect(dealer.dealer_name).to eq default_params[:dealer][:dealer_name]
        expect(dealer.en_dealer_name).to eq default_params[:dealer][:en_dealer_name]
        expect(dealer.status).to eq default_params[:dealer][:status]
        expect(dealer.bank_account).to eq default_params[:dealer][:bank_account]
        expect(dealer.address).to eq default_params[:dealer][:address]

        expect(dealer.update_user).to eq auth_token.tokenable
        expect(dealer.create_user).to eq auth_token.tokenable
      end
    end

    describe '業務エラー' do
      let(:dealer) { Dealer.last }

      it "エラーが返ること" do
        params = default_params.dup
        params[:dealer][:dealer_name] = ''
        params[:dealer][:en_dealer_name] = ''

        post :create_dealer, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["Dealer name can't be blank", "En dealer name can't be blank"]
        expect(Dealer.count).to eq 0
      end
    end
  end
end
