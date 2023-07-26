require 'rails_helper'

RSpec.describe Contractor::UserRegistrationController, type: :controller do
  before do
    FactoryBot.create(:system_setting)
  end

  describe '#create_user' do
    let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
    let(:contractor) { auth_token.tokenable.contractor }
    let(:contractor_user) { auth_token.tokenable }

    describe 'sms' do
      let(:params) {
        {
          auth_token: auth_token.token,
          contractor_user: {
            user_name: "1000000000009",
            full_name: "sakana",
            title_division: "division_name",
            mobile_number: "00011112222",
            line_id: "sakana-line"
          }
        } 
      }

      it '成功すること' do
        expect(contractor.contractor_users.count).to eq 1

        post :create_user, params: params

        expect(res[:success]).to eq true
        expect(contractor.contractor_users.count).to eq 2
      end
    end
  end
end
