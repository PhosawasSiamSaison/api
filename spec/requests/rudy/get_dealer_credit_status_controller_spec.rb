require 'rails_helper'

RSpec.describe Rudy::GetDealerCreditStatusController, type: :request do

  describe "#call" do
    let(:contractor) { FactoryBot.create(:contractor, approval_status: "qualified") }
    let(:cbm_dealer) { FactoryBot.create(:cbm_dealer) }
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

    before do
      FactoryBot.create(:available_product, contractor: contractor, dealer_type: :cbm,
          available: true)

      FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
      FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: cbm_dealer)
    end

    it "項目が正しく取得できること" do
      params = {
        tax_id: contractor.tax_id,
        dealer_code: cbm_dealer.dealer_code,
      }

      get rudy_get_dealer_credit_status_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      expect(res.has_key?(:dealer_credit_limit)).to eq true
      expect(res.has_key?(:dealer_used_amount)).to eq true
      expect(res.has_key?(:dealer_available_balance)).to eq true
    end
  end
end
