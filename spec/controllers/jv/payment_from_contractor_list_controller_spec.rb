require 'rails_helper'

RSpec.describe Jv::PaymentFromContractorListController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20190115')
  end

  describe '#search' do
    describe 'レスポンス' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        contractor.update!(tax_id: '1234567890123', en_company_name: 'Test Contractor')

        payment =
          FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: BusinessDay.today_ymd)

        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          search: {
            tax_id: "1234567890123",
            company_name: "Test Contractor",
            repayment_status: "all"
          }
        }

        get :search, params: params
        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 1
        expect(res[:total_count]).to eq 1
      end
    end

    describe 'Not Due Yetのステータス表示チェック' do
      let(:contractor) { FactoryBot.create(:contractor, check_payment: true) }

      before do
        FactoryBot.create(:evidence, contractor: contractor)

        payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20210315')

        inputed_order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        FactoryBot.create(:installment, order: inputed_order, payment: payment)

        not_inputed_order = FactoryBot.create(:order, contractor: contractor)
        FactoryBot.create(:installment, order: not_inputed_order, payment: payment)
      end

      it 'inputあり・なし混在は Not Input Dateのステータス表示になること' do
        params = {
          auth_token: auth_token.token,
          search: {
            tax_id: "",
            company_name: "",
            repayment_status: "all"
          }
        }

        get :search, params: params

        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 1
        expect(res[:payments].first[:repayment_status][:code]).to eq 'not_input_yet'
      end
    end
  end

  describe '#repayment_status_list' do
    it '正常に値が取得できること' do
      params = {
        auth_token: auth_token.token
      }

      get :repayment_status_list, params: params
      expect(res[:success]).to eq true
      expect(res[:list].present?).to eq true
    end
  end
end
