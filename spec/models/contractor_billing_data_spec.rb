# frozen_string_literal: true
# == Schema Information
#
# Table name: contractor_billing_data
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  th_company_name      :string(255)
#  address              :string(255)
#  tax_id               :string(13)       not null
#  due_ymd              :string(8)        not null
#  credit_limit         :decimal(13, 2)
#  available_balance    :decimal(13, 2)
#  due_amount           :decimal(13, 2)
#  cut_off_ymd          :string(8)        not null
#  installments_json    :text(65535)
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#

require 'rails_helper'

RSpec.describe ContractorBillingData, type: :model do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day)
  end

  describe '#pdf_dealer_type_format' do
    it '全てのdealer_typeからPDFフォーマットが取得できること' do
      ApplicationRecord.dealer_types.each do |k, v|
        installment_data = { 'dealer_type' => v }

        pdf_format_type = ContractorBillingData.new.send(:pdf_dealer_type_format, installment_data)
        expect([:sss, :cps].include?(pdf_format_type)).to eq true
      end
    end

    it '再約定のinstallmentはSSSフォーマットになること' do
      installment_data = { 'is_rescheduled' => true }

      pdf_format_type = ContractorBillingData.new.send(:pdf_dealer_type_format, installment_data)
      expect(pdf_format_type).to eq :sss
    end
  end

  describe '#search' do
    let(:contractor1) { FactoryBot.create(:contractor, en_company_name: 'test1') }
    let(:contractor2) { FactoryBot.create(:contractor, en_company_name: 'test2') }

    before do
      FactoryBot.create(:contractor_billing_data, contractor: contractor1)
      FactoryBot.create(:contractor_billing_data, contractor: contractor2)
    end

    it "Column 'th_company_name' in where clause is ambiguous のエラーが出ないこと" do
      params = {
        search: { company_name: 'test1' }
      }

      contractor_billing_data_list, total_count = ContractorBillingData.search(params)
      expect(contractor_billing_data_list.count).to eq 1
    end
  end
end
