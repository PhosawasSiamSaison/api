# frozen_string_literal: true
# == Schema Information
#
# Table name: payments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :integer          not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  paid_up_operated_ymd :string(8)
#  total_amount         :decimal(10, 2)   default(0.0), not null
#  paid_total_amount    :decimal(10, 2)   default(0.0), not null
#  paid_exceeded        :decimal(10, 2)   default(0.0), not null
#  paid_cashback        :decimal(10, 2)   default(0.0), not null
#  status               :integer          default("not_due_yet"), not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe Payment, type: :model do
  let(:area) { FactoryBot.create(:area) }
  let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }
  let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product8) { Product.find_by(product_key: 8) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190115')
  end

  describe '#installments' do
    let(:payment) { FactoryBot.create(:payment) }

    before do
      # InputDateあり
      order1 = FactoryBot.create(:order, input_ymd: '20220307')
      FactoryBot.create(:installment, order: order1, payment: payment)

      # InputDateなし
      order2 = FactoryBot.create(:order)
      FactoryBot.create(:installment, order: order2, payment: payment)
    end

    it 'InputDateありのみが含まれること' do
      expect(payment.installments.count).to eq 1
      expect(payment.installments.first.order.input_ymd).to eq '20220307'
    end
  end

  describe '.next_payment' do
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102')}
    let(:next_order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102')}

    context 'next_due' do
      let(:payment) {
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190315') }
      let(:next_payment) {
        FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20190215') }

      before do
        FactoryBot.create(:installment, order: order, payment: payment)
        FactoryBot.create(:installment, order: next_order, payment: next_payment)
      end

      it 'due_ymdの近いpaymentが取得できること' do
        expect(contractor.next_payment).to eq next_payment
      end
    end

    context 'not_due_yet' do
      let(:payment) {
        FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190315') }
      let(:next_payment) {
        FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190215') }

      before do
        FactoryBot.create(:installment, order: order, payment: payment)
        FactoryBot.create(:installment, order: next_order, payment: next_payment)
      end

      it 'due_ymdの近いpaymentが取得できること' do
        expect(contractor.next_payment).to eq next_payment
      end

      context 'input_ymdがnil' do
        before do
          order.update!(input_ymd: nil)
          next_order.update!(input_ymd: nil)
        end

        it 'nilになること' do
          expect(contractor.next_payment).to eq nil
        end
      end
    end
  end

  describe '.search_repayment_history' do
    let(:default_params) {
      {
        search: {
          tax_id: "",
          company_name: "",
          due_ymd: "",
          paid_up_ymd: "",
          over_due_only: "false",
          used_cashback_only: "false"
        },
        page: "1",
        per_page: "10"
      }
    }

    describe '正常値のチェック' do
      before do
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'パラメーターが空欄で取得できること' do
        payments, total_count = Payment.search_repayment_history(default_params)

        expect(payments.count).to eq 1
        expect(total_count).to eq 1
      end
    end

    describe 'tax_id' do
      before do
        contractor.update!(tax_id: '1000000000000')
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '正常に値が取得できること' do
        params = default_params
        params[:search][:tax_id] = '1000000000000'

        payments, total_count = Payment.search_repayment_history(default_params)

        expect(payments.first.contractor.tax_id).to eq '1000000000000'
      end
    end

    describe 'company_name' do
      before do
        contractor.update!(th_company_name: 'th-company', en_company_name: 'en-company')
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '正常に値が取得できること' do
        params = default_params

        # th
        params[:search][:company_name] = 'th-company'

        payments, total_count = Payment.search_repayment_history(default_params)
        expect(payments.first.contractor.th_company_name).to eq 'th-company'

        # en
        params[:search][:company_name] = 'en-company'

        payments, total_count = Payment.search_repayment_history(default_params)
        expect(payments.first.contractor.en_company_name).to eq 'en-company'
      end
    end

    describe 'due_ymd' do
      before do
        # 20190101
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190101')
        FactoryBot.create(:installment, order: order, payment: payment)

        # 20190102
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor, due_ymd: '20190102')
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '正常に値が取得できること' do
        params = default_params
        params[:search][:due_ymd] = '20190101'

        payments, total_count = Payment.search_repayment_history(default_params)
        expect(payments.pluck(:due_ymd)).to eq ['20190101']
      end
    end

    describe 'paid_up_ymd' do
      before do
        # 20190101
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor, paid_up_ymd: '20190101')
        FactoryBot.create(:installment, order: order, payment: payment)

        # 20190102
        order = FactoryBot.create(:order, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor, paid_up_ymd: '20190102')
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '正常に値が取得できること' do
        params = default_params
        params[:search][:paid_up_ymd] = '20190102'

        payments, total_count = Payment.search_repayment_history(default_params)
        expect(payments.pluck(:paid_up_ymd)).to eq ['20190102']
      end
    end
  end

  describe '#payment_from_contractor_payments' do
    describe '過去に支払い済、遅延、今日が期限(未払い)、次の支払い(未払い)、未確定の支払い、がそれぞれ1件づつ' do
      before do
        payment1 = Payment.create!(contractor: contractor, total_amount:  500.0, due_ymd: '20181215',
          status: 'paid', paid_up_ymd: '20181215', paid_up_operated_ymd: '20181215')
        payment2 = Payment.create!(contractor: contractor, total_amount: 1000.0, due_ymd: '20181231',
          status: 'over_due', paid_up_ymd: nil, paid_up_operated_ymd: nil)
        payment3 = Payment.create!(contractor: contractor, total_amount: 2000.0, due_ymd: '20190115',
          status: 'next_due', paid_up_ymd: nil, paid_up_operated_ymd: nil)
        payment4 = Payment.create!(contractor: contractor, total_amount: 4000.0, due_ymd: '20190131',
          status: 'next_due', paid_up_ymd: nil, paid_up_operated_ymd: nil)
        payment5 = Payment.create!(contractor: contractor, total_amount: 8000.0, due_ymd: '20190215',
          status: 'not_due_yet', paid_up_ymd: nil, paid_up_operated_ymd: nil)

        order1 = FactoryBot.create(:order, :inputed_date)

        FactoryBot.create(:installment, order: order1, payment: payment1)
        FactoryBot.create(:installment, order: order1, payment: payment2)
        FactoryBot.create(:installment, order: order1, payment: payment3)
        FactoryBot.create(:installment, order: order1, payment: payment4)
        FactoryBot.create(:installment, order: order1, payment: payment5)
      end

      it '遅延、今日が約定日(未払い)、次の支払い(未払い)、が取得できること' do
        payments = contractor.payments.payment_from_contractor_payments

        expect(payments.count).to eq 4

        # 遅延
        expect(payments.first.status).to eq 'over_due'
        # 今日が約定日(未払い)
        expect(payments.second.status).to eq 'next_due'
        expect(payments.second.due_ymd).to eq '20190115'
        # 次の支払い(未払い)
        expect(payments.third.status).to eq 'next_due'
        expect(payments.third.due_ymd).to eq '20190131'
        # NotDueYet(未払い)
        expect(payments[3].status).to eq 'not_due_yet'
        expect(payments[3].due_ymd).to eq '20190215'
      end
    end

    describe '遅延 が2件、今日が期限(支払済)、次の支払(支払)、がそれぞれ1件づつ' do
      before do
        payment1 = Payment.create!(contractor: contractor, total_amount:  500.0, due_ymd: '20181215',
          status: 'over_due', paid_up_ymd: nil, paid_up_operated_ymd: nil)
        payment2 = Payment.create!(contractor: contractor, total_amount: 1000.0, due_ymd: '20181231',
          status: 'over_due', paid_up_ymd: nil, paid_up_operated_ymd: nil)
        payment3 = Payment.create!(contractor: contractor, total_amount: 2000.0, due_ymd: '20190115',
          status: 'paid', paid_up_ymd: '20190115', paid_up_operated_ymd: '20190115')
        payment4 = Payment.create!(contractor: contractor, total_amount: 4000.0, due_ymd: '20190131',
          status: 'paid', paid_up_ymd: '20190115', paid_up_operated_ymd: '20190115')

        order1 = FactoryBot.create(:order, :inputed_date)

        FactoryBot.create(:installment, order: order1, payment: payment1)
        FactoryBot.create(:installment, order: order1, payment: payment2)
        FactoryBot.create(:installment, order: order1, payment: payment3)
        FactoryBot.create(:installment, order: order1, payment: payment4)
      end

      it '遅延 が2件、今日が期限(支払済)、次の支払(支払)、が取得できること' do
        payments = contractor.payments.payment_from_contractor_payments

        expect(payments.count).to eq 4

        # 遅延 1
        expect(payments.first.status).to eq 'over_due'
        expect(payments.first.due_ymd).to eq '20181215'
        # 遅延 2
        expect(payments.second.status).to eq 'over_due'
        expect(payments.second.due_ymd).to eq '20181231'
        # 今日が約定日(支払済)
        expect(payments.third.status).to eq 'paid'
        expect(payments.third.due_ymd).to eq '20190115'
        # 次の支払い(支払済)
        expect(payments.fourth.status).to eq 'paid'
        expect(payments.fourth.due_ymd).to eq '20190131'
      end
    end
  end

  describe '#remaining_balance' do
    context 'orderのinput_ymdあり' do
      let(:payment) {
        FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190215') }
      let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102') }

      before do
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '支払い金額があること' do
        expect(payment.remaining_balance).to be > 0
      end
    end

    context 'orderのinput_ymdなし' do
      let(:payment) {
        FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20190215') }
      let(:order) { FactoryBot.create(:order, contractor: contractor) }

      before do
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '支払い金額があること' do
        expect(payment.remaining_balance).to eq 0
      end
    end
  end

  describe '#all_orders_input_ymd_blank?' do
    let(:payment) {
        FactoryBot.create(:payment, :not_due_yet, contractor: contractor) }

    context 'input_ymdあり' do
      let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102')}

      before do
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'falseになること' do
        expect(payment.all_orders_input_ymd_blank?).to eq false
      end
    end

    context 'input_ymdなし' do
      let(:order) { FactoryBot.create(:order, contractor: contractor)}

      before do
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'trueになること' do
        expect(payment.all_orders_input_ymd_blank?).to eq true
      end
    end

    context 'input_ymd一部あり' do
      let(:order1) { FactoryBot.create(:order, contractor: contractor)}
      let(:order2) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102')}

      before do
        FactoryBot.create(:installment, order: order1, payment: payment)
        FactoryBot.create(:installment, order: order2, payment: payment)
      end

      it 'falseになること' do
        expect(payment.all_orders_input_ymd_blank?).to eq false
      end
    end
  end

  describe '#has_can_apply_change_product_order?' do
    let(:payment) { FactoryBot.create(:payment) }

    context 'Input date あり' do
      let(:order) { FactoryBot.create(:order, :inputed_date) }

      context '一部支払済' do
        before do
          FactoryBot.create(:installment, payment: payment, order: order,
            due_ymd: '20190215', paid_principal: 1)
        end

        it '含まれないこと' do
          expect(payment.has_can_apply_change_product_order?).to eq false
        end
      end

      context '申請可能のオーダーあり' do
        before do
          FactoryBot.create(:installment, payment: payment, order: order, due_ymd: '20190215')
        end

        it '含まれること' do
          expect(payment.has_can_apply_change_product_order?).to eq true
        end
      end

      context '申請可能なし と 申請可能あり' do
        before do
          FactoryBot.create(:installment, payment: payment, order: order, due_ymd: '20190215',
            paid_principal: 1)

          order2 = FactoryBot.create(:order, :inputed_date)
          FactoryBot.create(:installment, payment: payment, order: order2, due_ymd: '20190215')
        end

        it '含まれること' do
          expect(payment.has_can_apply_change_product_order?).to eq true
        end
      end
    end

    context 'Input date なし' do
      let(:order) { FactoryBot.create(:order, input_ymd: nil) }

      before do
        FactoryBot.create(:installment, payment: payment, order: order, due_ymd: '20190215')
      end

      it '判定に含まれないこと' do
        expect(payment.has_can_apply_change_product_order?).to eq false
      end
    end
  end

  describe 'due_basis_data' do
    let(:payment) { FactoryBot.create(:payment) }

    context 'Input date あり' do
      let(:order) { FactoryBot.create(:order, :inputed_date) }

      before do
        FactoryBot.create(:installment, payment: payment, order: order)
      end

      it '含まれること' do
        expect(Payment.due_basis_data.count).to eq 1
      end
    end

    context 'Input date なし' do
      let(:order) { FactoryBot.create(:order, input_ymd: nil) }

      before do
        FactoryBot.create(:installment, payment: payment, order: order)
      end

      it '含まれないこと' do
        expect(Payment.due_basis_data.count).to eq 0
      end
    end

    context 'Input date なし と あり' do
      let(:order1) { FactoryBot.create(:order, input_ymd: nil) }
      let(:order2) { FactoryBot.create(:order, :inputed_date) }

      before do
        FactoryBot.create(:installment, payment: payment, order: order1,
          principal: 1, interest: 0.1, due_ymd: '20190115')
        FactoryBot.create(:installment, payment: payment, order: order2,
          principal: 2, interest: 0.2, due_ymd: '20190115')
      end

      it '含まれないこと' do
        payments = Payment.due_basis_data
        expect(payments.count).to eq 1

        payment = payments.first
        today_ymd = BusinessDay.today_ymd

        expect(payment.total_principal).to eq 2
        expect(payment.total_interest).to eq 0.2
        expect(payment.calc_total_late_charge(today_ymd)).to eq 0
        expect(payment.calc_total_amount(today_ymd)).to eq 2.2
        expect(payment.remaining_balance(today_ymd)).to eq 2.2
      end
    end
  end

  describe '#has_15day_products?' do
    let(:payment) { FactoryBot.create(:payment) }

    context 'orderなし' do
      it 'falseになること' do
        expect(payment.has_15day_products?).to eq false
      end
    end

    context '15日商品' do
      before do
        order = FactoryBot.create(:order, :inputed_date, product: product8)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'trueになること' do
        expect(payment.has_15day_products?).to eq true
      end

      context '30日商品を追加' do
        before do
          order = FactoryBot.create(:order, :inputed_date, product: product1)
          FactoryBot.create(:installment, order: order, payment: payment)
        end

        it 'trueになること' do
          expect(payment.has_15day_products?).to eq true
        end
      end
    end

    context '30日商品のみ' do
      before do
        order = FactoryBot.create(:order, :inputed_date, product: product1)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'falseになること' do
        expect(payment.has_15day_products?).to eq false
      end
    end

    context 'InputDateなし15日商品' do
      before do
        order = FactoryBot.create(:order, product: product8)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'falseになること' do
        expect(payment.has_15day_products?).to eq false
      end
    end
  end
end
