# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CalcSelectedPaymentSubtractions, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20190114')
  end

  context 'Normal value' do
    before do
      order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190114', purchase_amount: 50)
      payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', status: 'not_due_yet', total_amount: 50)
      FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215', principal: 50)
      order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190214', purchase_amount: 100)
      order3 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190214', purchase_amount: 50)
      payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315', status: 'not_due_yet', total_amount: 150)
      FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190315', principal: 100)
      FactoryBot.create(:installment, order: order3, payment: payment2, due_ymd: '20190315', principal: 50)
    end

    it 'Should obtain values normally' do
      paid_installment1 = Installment.first
      paid_installment3 = Installment.last
      payment_subtractions = CalcSelectedPaymentSubtractions.new(
        contractor,
        installment_ids: [paid_installment1.id, paid_installment3.id]
      ).call
      paid_payment = Payment.first
      next_payment = Payment.last

      expect(payment_subtractions.count).to eq 2
      # next_due
      expect(payment_subtractions[next_payment.id][:exceeded].is_a?(Float)).to eq true
      # paid
      expect(payment_subtractions[paid_payment.id][:exceeded].is_a?(Float)).to eq true
    end
  end
end
