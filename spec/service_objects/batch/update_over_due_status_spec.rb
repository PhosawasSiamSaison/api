# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::UpdateOverDueStatus do
  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190215')
  end

  describe '約定日に支払いがなかった（statusがpaidではない）Payment' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }
    let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
    let(:product1) { Product.find_by(product_key: 1)}

    before do
      order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product1, installment_count: product1.number_of_installments,
        purchase_ymd: '20190101', input_ymd: '20190110', input_ymd_updated_at: '2019-01-10 10:00:00',
        purchase_amount: 1000.01, order_user: contractor_user)

      payment = Payment.create!(contractor: contractor, due_ymd: '20190215',
        total_amount: 1000.01, status: 'next_due')

      FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
        due_ymd: '20190215', principal: 900.01, interest: 100)
    end

    it 'statusがover_dueになること' do
      payment = Payment.find_by(due_ymd: '20190215')

      expect(payment.status).to eq 'next_due'

      Batch::UpdateOverDueStatus.exec

      expect(payment.reload.status).to eq 'over_due'
    end
  end
end
