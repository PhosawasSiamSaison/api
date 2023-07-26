# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateContractorBillingPDF, type: :model do
  before do
    FactoryBot.create(:contractor_billing_data)
  end

  describe 'call' do
    it 'エラーにならないこと' do
      contractor_billing_data = ContractorBillingData.first

      pdf, file_name = GenerateContractorBillingPDF.new.call(contractor_billing_data)

      expect(file_name.present?).to eq true
    end
  end
end
