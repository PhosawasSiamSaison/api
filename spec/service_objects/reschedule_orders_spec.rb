# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RescheduleOrders, type: :model do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:area) { FactoryBot.create(:area) }
  let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }
  let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
  let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:product3) { Product.find_by(product_key: 3) }
  let(:product4) { Product.find_by(product_key: 4) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190228')
    FactoryBot.create(:eligibility, contractor: contractor, limit_amount: 1000.0, latest: true)
  end

  context 'Fee Orderあり' do
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

    before do
      payment = FactoryBot.create(:payment, due_ymd: '20190228', total_amount: 110)
      FactoryBot.create(:installment, order: order, payment: payment, principal: 100, interest: 10)
    end

    it '成功' do
      RescheduleOrders.new.call(contractor.id, '20190228', [order.id], 1, 3, false, true, jv_user)

      expect(contractor.orders.count).to eq 3

      old_order = contractor.orders.first
      fee_order = contractor.orders.second
      new_order = contractor.orders.third

      expect(old_order.rescheduled?).to eq true
      expect(old_order.rescheduled_fee_order).to eq fee_order
      expect(old_order.rescheduled_new_order).to eq new_order
      expect(old_order.installments.all?(&:rescheduled)).to eq true

      expect(fee_order.rescheduled_new_order?).to eq true
      expect(fee_order.fee_order).to eq true
      expect(fee_order.order_number).to eq 'RF201902280001'
      expect(fee_order.input_ymd).to eq BusinessDay.today_ymd
      expect(fee_order.installment_count).to eq 3
      expect(fee_order.installments.count).to eq 3
      expect(fee_order.product).to eq nil

      expect(new_order.rescheduled_new_order?).to eq true
      expect(new_order.fee_order).to eq false
      expect(new_order.order_number).to eq 'RS201902280001'
      expect(new_order.input_ymd).to eq BusinessDay.today_ymd
      expect(new_order.installment_count).to eq 1
      expect(new_order.installments.count).to eq 1
      expect(new_order.product).to eq nil
    end

    describe 'Exceeded/Cashbackの自動消し込み' do
      let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          order_number: order.order_number,
          dealer_code: order.dealer.dealer_code,
          input_date: "20220717"
        }
      }

      before do
        JvService::Application.config.auto_repayment_exceeded_and_cashback = true

        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :not_due_yet, due_ymd: '20221015', contractor: contractor),
          order: FactoryBot.create(:order, :inputed_date, contractor: contractor),
          due_ymd: '20221015', principal: 100,
        )

        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :next_due, due_ymd: '20220930', contractor: contractor),
          order: order,
          due_ymd: '20220930', principal: 100,
        )

        contractor.update!(pool_amount: 100)
      end

      it '自動消し込みが実行されていること' do
        RescheduleOrders.new.call(contractor.id, '20190228', [order.id], 1, 3, false, true, jv_user)

        expect(contractor.receive_amount_histories.count).to eq 1
        expect(contractor.receive_amount_histories.first.comment).to eq I18n.t('message.auto_repayment_exceeded_and_cashback_comment')
        expect(MailSpool.receive_payment.count).to eq 1
      end
    end
  end

  context 'Fee Orderなし' do
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

    before do
      payment = FactoryBot.create(:payment, due_ymd: '20190228', total_amount: 100)
      FactoryBot.create(:installment, order: order, payment: payment,
        principal: 100, interest: 0, due_ymd: '20190228')
    end

    it '成功' do
      RescheduleOrders.new.call(contractor.id, '20190228', [order.id],
        1, 1, true, true, jv_user)

      expect(contractor.orders.count).to eq 2

      order1 = contractor.orders.first
      order2 = contractor.orders.second

      expect(order1.rescheduled?).to eq true
      expect(order2.rescheduled_new_order?).to eq true
      expect(order2.order_number).to eq 'RS201902280001'
    end
  end

  describe 'set_credit_limit_to_zero' do
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

    before do
      payment = FactoryBot.create(:payment, due_ymd: '20190228', total_amount: 100)
      FactoryBot.create(:installment, order: order, payment: payment,
        principal: 100, interest: 0, due_ymd: '20190228')
    end

    it 'Credit Limitを0へ' do
      RescheduleOrders.new.call(contractor.id, '20190228', [order.id],
        1, 1, false, true, jv_user)

      expect(contractor.credit_limit_amount).to eq 0
    end

    it 'Credit Limitはそのまま' do
      RescheduleOrders.new.call(contractor.id, '20190228', [order.id],
        1, 1, true, false, jv_user)

      expect(contractor.credit_limit_amount).to_not eq 0
    end
  end
end
