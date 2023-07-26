# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChangeProductPaymentSchedule, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20190131')
  end

  context '正常値' do
    before do
      payment1 = FactoryBot.create(:payment, :paid, due_ymd: '20190115',contractor: contractor, paid_exceeded: 1.0)
      payment2 = FactoryBot.create(:payment, :next_due, due_ymd: '20190131', contractor: contractor, paid_exceeded: 1.0)

      order1 = FactoryBot.create(:order, :inputed_date)
      order2 = FactoryBot.create(:order, :inputed_date)

      FactoryBot.create(:installment, order: order1, payment: payment1)
      FactoryBot.create(:installment, order: order2, payment: payment2)
    end

    it '正常に値が取得できること' do
      payment_subtractions = CalcPaymentSubtractions.new(contractor).call
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
