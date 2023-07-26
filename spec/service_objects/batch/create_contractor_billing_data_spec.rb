# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::CreateContractorBillingData do
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:product8) { Product.find_by(product_key: 8) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20220115')
  end

  describe '通常パターン' do
    let(:payment) {
      FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20220215')
    }
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20220110') }

    before do
      FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20220215')
    end

    it 'データが正しく保存されること' do
      Batch::CreateContractorBillingData.exec

      expect(ContractorBillingData.all.count).to eq 1

      billing_data = ContractorBillingData.first
      expect(billing_data.due_ymd).to eq '20220215'
      expect(billing_data.cut_off_ymd).to eq '20220115'

      installments_data = JSON.parse(billing_data.installments_json)
      expect(installments_data.count).to eq 1

      installment_data = installments_data.first
      expect(installment_data['input_ymd']).to eq '20220110'
    end

    context '30日商品ありをDueDate１５日前の締め日での処理' do
      before do
        Batch::CreateContractorBillingData.exec

        BusinessDay.update_ymd!('20220131')
      end

      it 'データが変更されないこと' do
        Batch::CreateContractorBillingData.exec

        expect(ContractorBillingData.all.count).to eq 1

        billing_data = ContractorBillingData.first
        expect(billing_data.due_ymd).to eq '20220215'
        expect(billing_data.cut_off_ymd).to eq '20220115'
      end
    end

    context '既存の30日商品ありのデータに１５日商品を追加したパターン' do
      before do
        # 日付更新前に実行
        Batch::CreateContractorBillingData.exec

        BusinessDay.update_ymd!('20220131')

        order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20220116',
          product: product8)

        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20220215')
      end

      it 'データが１５日商品を含む最新に更新されること' do
        Batch::CreateContractorBillingData.exec

        expect(ContractorBillingData.all.count).to eq 1

        billing_data = ContractorBillingData.first
        expect(billing_data.due_ymd).to eq '20220215'
        expect(billing_data.cut_off_ymd).to eq '20220131'

        installments_data = JSON.parse(billing_data.installments_json)
        expect(installments_data.count).to eq 2

        installment_data = installments_data.first
        expect(installment_data['input_ymd']).to eq '20220110'

        installment_data = installments_data.last
        expect(installment_data['input_ymd']).to eq '20220116'
      end
    end
  end

  describe '15日商品のみ' do
    before do
      BusinessDay.update_ymd!('20220131')

      payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20220215')
      order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20220116',
        product: product8)

      FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20220215')
    end

    it 'データが正しく保存されること' do
      Batch::CreateContractorBillingData.exec

      expect(ContractorBillingData.all.count).to eq 1

      billing_data = ContractorBillingData.first
      expect(billing_data.due_ymd).to eq '20220215'
      expect(billing_data.cut_off_ymd).to eq '20220131'

      installments_data = JSON.parse(billing_data.installments_json)
      expect(installments_data.count).to eq 1

      installment_data = installments_data.first
      expect(installment_data['input_ymd']).to eq '20220116'
    end
  end

  describe '同じ締め日で異なるDueDate（１５と３０日商品）' do
    before do
      # 15日商品
      payment1 = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20220131')
      order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20220110')
      FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20220131')

      # ３０日商品
      payment2 = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20220215')
      order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20220110')
      FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20220215')
    end

    it '別々のデータで作成されること' do
      Batch::CreateContractorBillingData.exec

      expect(ContractorBillingData.all.count).to eq 2
    end
  end

  describe 'paidのpayment' do
    let(:payment) {
      FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20220215')
    }
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20220110') }

    before do
      FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20220215')
    end

    it 'paidのデータが保存されること' do
      Batch::CreateContractorBillingData.exec

      expect(ContractorBillingData.all.count).to eq 1
    end
  end
end
