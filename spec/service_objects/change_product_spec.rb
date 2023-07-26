# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChangeProduct, type: :model do
  let(:auth_token) { FactoryBot.create(:auth_token, :jv) }
  let(:jv_user) { auth_token.tokenable }
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:system_setting)
  end

  context '1 -> 3' do
    let(:product2) { Product.find_by(product_key: 2) }
    let(:order) {
      FactoryBot.create(:order, contractor: contractor, purchase_ymd: '20190101',
        purchase_amount: 3000, input_ymd: '20190101')
    }

    context 'not_due_yet' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190101')

        payment = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190215',
          total_amount: 3000)
        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常に値が更新されること' do
        result = ChangeProduct.new(order, product2).call
        order.reload

        expect(result[:success]).to eq true
        expect(order.installment_count).to eq 3
        expect(order.product.number_of_installments).to eq 3
        expect(order.change_product_before_due_ymd).to eq '20190215'

        installments = order.installments
        expect(installments.count).to eq 3
        expect(installments.first.due_ymd).to eq  '20190215'
        expect(installments.second.due_ymd).to eq '20190315'
        expect(installments.third.due_ymd).to eq  '20190415'

        expect(installments.first.principal).to eq  1000
        expect(installments.second.principal).to eq 1000
        expect(installments.third.principal).to eq  1000

        expect(installments.first.interest).to eq  25.1
        expect(installments.second.interest).to eq 25.1
        expect(installments.third.interest).to eq  25.1

        expect(installments.first.payment.due_ymd).to eq  '20190215'
        expect(installments.second.payment.due_ymd).to eq '20190315'
        expect(installments.third.payment.due_ymd).to eq  '20190415'

        expect(installments.first.payment.status).to eq  'not_due_yet'
        expect(installments.second.payment.status).to eq 'not_due_yet'
        expect(installments.third.payment.status).to eq  'not_due_yet'

        expect(installments.first.payment.total_amount).to eq  1025.1
        expect(installments.second.payment.total_amount).to eq 1025.1
        expect(installments.third.payment.total_amount).to eq  1025.1
      end
    end

    context 'next_due' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190116')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215',
          total_amount: 3000)
        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 3000, interest: 0)
      end

      it '正常に値が更新されること' do
        result = ChangeProduct.new(order, product2).call
        order.reload

        expect(result[:success]).to eq true
        expect(order.installment_count).to eq 3
        expect(order.product.number_of_installments).to eq 3
        expect(order.change_product_before_due_ymd).to eq '20190215'

        installments = order.installments
        expect(installments.count).to eq 3
        expect(installments.first.due_ymd).to eq  '20190215'
        expect(installments.second.due_ymd).to eq '20190315'
        expect(installments.third.due_ymd).to eq  '20190415'

        expect(installments.first.principal).to eq  1000
        expect(installments.second.principal).to eq 1000
        expect(installments.third.principal).to eq  1000

        expect(installments.first.interest).to eq  25.1
        expect(installments.second.interest).to eq 25.1
        expect(installments.third.interest).to eq  25.1

        expect(installments.first.payment.due_ymd).to eq  '20190215'
        expect(installments.second.payment.due_ymd).to eq '20190315'
        expect(installments.third.payment.due_ymd).to eq  '20190415'

        expect(installments.first.payment.status).to eq  'next_due'
        expect(installments.second.payment.status).to eq 'not_due_yet'
        expect(installments.third.payment.status).to eq  'not_due_yet'

        expect(installments.first.payment.total_amount).to eq  1025.1
        expect(installments.second.payment.total_amount).to eq 1025.1
        expect(installments.third.payment.total_amount).to eq  1025.1
      end
    end

    context '他のpaymentあり' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190215')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215',
          total_amount: 5050.2)

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 3000, interest: 0)


        order2 = FactoryBot.create(:order, contractor: contractor, product: product2, purchase_ymd: '20190101',
            installment_count: 3, purchase_amount: 6000, input_ymd: '20190115')

        payment2 = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190315',
          total_amount: 2050.2)
        payment3 = FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190415',
          total_amount: 2050.2)

        FactoryBot.create(:installment, order: order2, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 2000, interest: 50.2)
        FactoryBot.create(:installment, order: order2, payment: payment2,
          installment_number: 2, due_ymd: '20190315', principal: 2000, interest: 50.2)
        FactoryBot.create(:installment, order: order2, payment: payment3,
          installment_number: 3, due_ymd: '20190415', principal: 2000, interest: 50.2)
      end

      it 'paymentの値が正しいこと' do
        result = ChangeProduct.new(order, product2).call
        order.reload
        expect(order.installment_count).to eq 3
        expect(order.payments.count).to eq 3
        expect(order.installments.count).to eq 3
        expect(order.product.number_of_installments).to eq 3

        installments = order.installments

        contractor = order.contractor
        expect(contractor.payments.count).to eq 3
        expect(contractor.payments.find_by(due_ymd: '20190215').status).to eq 'next_due'
        expect(contractor.payments.find_by(due_ymd: '20190315').status).to eq 'not_due_yet'
        expect(contractor.payments.find_by(due_ymd: '20190415').status).to eq 'not_due_yet'
      end
    end
  end

  describe 'update_payment_status' do
    context '中間の約定日' do
      let(:payment) { FactoryBot.create(:payment, :not_due_yet, due_ymd: '20200215') }

      context '業務日が1/15' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20200115')
        end

        it 'not_due_yetになること' do
          ChangeProduct.new(payment.orders.first, nil).send(:update_payment_status, payment)
          expect(payment.status).to eq 'not_due_yet'
        end
      end

      context '業務日が1/16' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20200116')
        end

        it 'next_dueになること' do
          ChangeProduct.new(payment.orders.first, nil).send(:update_payment_status, payment)
          expect(payment.status).to eq 'next_due'
        end
      end

      context '業務日が2/16' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20200216')
        end

        it 'over_dueになること' do
          ChangeProduct.new(payment.orders.first, nil).send(:update_payment_status, payment)
          expect(payment.status).to eq 'over_due'
        end
      end
    end

    context '月末の約定日' do
      let(:payment) { FactoryBot.create(:payment, :not_due_yet, due_ymd: '20200229') }

      context '業務日が1/31' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20200131')
        end

        it 'not_due_yetになること' do
          ChangeProduct.new(payment.orders.first, nil).send(:update_payment_status, payment)
          expect(payment.status).to eq 'not_due_yet'
        end
      end

      context '業務日が2/1' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20200201')
        end

        it 'next_dueになること' do
          ChangeProduct.new(payment.orders.first, nil).send(:update_payment_status, payment)
          expect(payment.status).to eq 'next_due'
        end
      end

      context '業務日が3/1' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20200301')
        end

        it 'over_dueになること' do
          ChangeProduct.new(payment.orders.first, nil).send(:update_payment_status, payment)
          expect(payment.status).to eq 'over_due'
        end
      end
    end
  end

  describe 'payment.statusの更新' do
    let(:order1) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20200831') }
    let(:payment) { FactoryBot.create(:payment, :next_due, total_amount: 300) }
    let(:product4) { Product.find_by(product_key: 4) }

    before do
      FactoryBot.create(:business_day, business_ymd: '20201001')

      FactoryBot.create(:installment, order: order1, payment: payment, principal: 100)

      # 支払い済みにするオーダー
      order2 = FactoryBot.create(:order, :inputed_date, contractor: contractor)
      FactoryBot.create(:installment, order: order2, payment: payment, paid_up_ymd: '20201001',
        principal: 300)
    end

    it '支払い済みのinstallmentがある場合に、他のinstallmentをcancelした場合にpayment.statusがpaidになること' do
      # due_ymdがズレる商品を指定する
      result = ChangeProduct.new(order1, product4).call

      expect(result[:success]).to eq true
      expect(payment.reload.status).to eq 'paid'
    end
  end
end
