# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateOrder, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20220716')
    FactoryBot.create(:system_setting)
  end

  describe 'payment.statusの検証' do
    context 'Product1' do
      let(:order) { FactoryBot.build(:order) }

      it '初期値がnot_due_yetになること' do
        CreateOrder.new.call(order)

        order.reload
        expect(order.payments.first.not_due_yet?).to eq true
      end
    end

    context 'Product8' do
      let(:order) { FactoryBot.build(:order, :product_key8) }

      it '初期値がnot_due_yetになること' do
        CreateOrder.new.call(order)

        order.reload
        expect(order.payments.first.not_due_yet?).to eq true
      end
    end

    context '既存のNextDue Payment(Product1のオーダー)あり' do
      let(:order) { FactoryBot.build(:order, :product_key8, purchase_ymd: '20220716', contractor: contractor) }

      before do
        order = FactoryBot.create(:order, :inputed_date, purchase_ymd: '20220715')
        payment = FactoryBot.create(:payment, :next_due, due_ymd: '20220815', contractor: contractor)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '15日商品を追加してもnext_dueのままであること' do
        CreateOrder.new.call(order)

        order.reload
        expect(order.payments.count).to eq 1
        expect(order.payments.first.next_due?).to eq true
      end
    end

    context '既存のPaid Payment(Product1のオーダー)あり' do
      let(:order) {
        Order.new(
          contractor: contractor,
          order_type: "",
          order_number: "order1",
          dealer: FactoryBot.create(:dealer, dealer_type: :permsin),
          second_dealer: nil,
          product: Product.find_by(product_key: 8),
          installment_count: 1,
          purchase_ymd: BusinessDay.today_ymd,
          purchase_amount: 100,
          input_ymd: nil,
          input_ymd_updated_at: nil,
          amount_without_tax: 100,
          second_dealer_amount: nil,
          site: FactoryBot.create(:site),
          region: "",
          rudy_purchase_ymd: BusinessDay.today_ymd,
          bill_date: "",
        )
      }

      context 'Input Dateなし(CBM系)' do
        before do
          order = FactoryBot.create(:order, purchase_ymd: '20220715')
          payment = FactoryBot.create(:payment, :paid, due_ymd: '20220815', paid_up_ymd: '20220716',
            contractor: contractor)
          FactoryBot.create(:installment, order: order, payment: payment)
        end

        it 'Input Dateがない場合はstatusは変わらないこと' do
          CreateOrder.new.call(order)

          order.reload
          expect(order.payments.count).to eq 1
          payment = order.payments.first
          expect(payment.paid?).to eq true
          expect(payment.paid_up_ymd.present?).to eq true
        end
      end

      context 'Input Dateあり(CPAC系)' do
        before do
          FactoryBot.create(:installment,
            order: FactoryBot.create(:order, purchase_ymd: '20220715', contractor: contractor),
            payment: FactoryBot.create(:payment, :paid, due_ymd: '20220815', paid_up_ymd: '20220716', contractor: contractor)
          )
        end

        it 'Input Dateがある場合はstatusが変わること' do
          order.input_ymd = BusinessDay.today_ymd

          CreateOrder.new.call(order)

          order.reload
          expect(order.payments.count).to eq 1
          payment = order.payments.first
          expect(payment.next_due?).to eq true
          expect(payment.paid_up_ymd.present?).to eq false
        end
      end
    end
  end
end
