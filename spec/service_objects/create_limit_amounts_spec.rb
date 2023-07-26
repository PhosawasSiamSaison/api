# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateLimitAmounts, type: :model do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:jv_user) { auth_token.tokenable }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:cbm_dealer) { FactoryBot.create(:cbm_dealer) }
  let(:product2) { Product.find_by(product_key: 2) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190115')
  end

  it 'Limitが0でも登録されること' do
    params = {
      auth_token: auth_token.token,
      contractor_id: contractor.id,
      eligibility: {
        limit_amount: 0,
        class_type: :b_class,
        comment: "new comment.",
        dealer_types: [
          {
            dealer_type: :cbm,
            limit_amount: 0,
            dealers: [
              {
                id: cbm_dealer.id,
                limit_amount: 0
              }
            ]
          }
        ]
      }
    }

    errors = CreateLimitAmounts.new.call(params, jv_user)

    expect(errors).to eq []
    expect(contractor.latest_dealer_type_limits.count).to eq 1
    expect(contractor.latest_dealer_limits.count).to eq 1
  end
end
