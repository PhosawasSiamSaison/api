# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChangeProductPaymentSchedule, type: :model do
  let(:auth_token) { FactoryBot.create(:auth_token, :contractor) }
  let(:contractor_user) { auth_token.tokenable }
  let(:contractor) { contractor_user.contractor }
  let(:order) { Order.first }
  let(:product2) { Product.find_by(product_key: 2) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190115')
  end

  context '正常値' do
    before do
      FactoryBot.create(:order, :inputed_date, contractor: contractor, purchase_ymd: '20190115',
        purchase_amount: 3000)
    end

    it '正常に値が取得できること' do
      new_installment = ChangeProductPaymentSchedule.new(order, product2).call

      expect(new_installment[:count]).to eq 3

      expect(new_installment[:schedules].is_a?(Array)).to eq true
      expect(new_installment[:schedules].first[:due_ymd].present? ).to eq true
      expect(new_installment[:schedules].second[:due_ymd].present?).to eq true
      expect(new_installment[:schedules].third[:due_ymd].present? ).to eq true

      expect(new_installment[:schedules].first[:amount] ).to be > 1000
      expect(new_installment[:schedules].second[:amount]).to be > 1000
      expect(new_installment[:schedules].third[:amount] ).to be > 1000

      expect(new_installment[:total_amount].is_a?(Float)).to eq true
      expect(new_installment[:total_amount]).to be > 3000
    end

    it 'productをnilで正しく値が取れること' do
      new_installment = ChangeProductPaymentSchedule.new(order, nil).call

      expect(new_installment[:count]).to eq 0
      expect(new_installment[:schedules]).to eq []

      expect(new_installment[:total_amount].is_a?(Float)).to eq true
      expect(new_installment[:total_amount]).to eq 0
    end
  end

  describe '日付の検証' do
    before do
      FactoryBot.create(:order, contractor: contractor,
        purchase_amount: 3000, purchase_ymd: '20190115', input_ymd: input_ymd)
    end

    context 'input_date: 1/1' do
      let(:input_ymd) { '20190101' }

      it '2/15' do
        new_installment = ChangeProductPaymentSchedule.new(order, product2).call
        expect(new_installment[:schedules].first[:due_ymd]).to eq '20190215'
      end
    end

    context 'input_date: 1/15' do
      let(:input_ymd) { '20190115' }

      it '2/15' do
        new_installment = ChangeProductPaymentSchedule.new(order, product2).call
        expect(new_installment[:schedules].first[:due_ymd]).to eq '20190215'
      end
    end

    context 'input_date: 1/16' do
      let(:input_ymd) { '20190116' }

      it '2/28' do
        new_installment = ChangeProductPaymentSchedule.new(order, product2).call
        expect(new_installment[:schedules].first[:due_ymd]).to eq '20190228'
      end
    end

    context 'input_date: 1/31' do
      let(:input_ymd) { '20190131' }

      it '2/28' do
        new_installment = ChangeProductPaymentSchedule.new(order, product2).call
        expect(new_installment[:schedules].first[:due_ymd]).to eq '20190228'
      end
    end
  end
end
