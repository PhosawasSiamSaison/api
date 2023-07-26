require 'rails_helper'

RSpec.describe Jv::RepaymentHistoryController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }

  describe '#search' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
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
      }.dup
    }

    describe 'レスポンス' do
      before do
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor,
          due_ymd: '20190101', paid_up_ymd: '20190101')
        FactoryBot.create(:installment, order: order, payment: payment,
          due_ymd: '20190101', paid_up_ymd: '20190101')
      end

      it '正常に値が取得できること' do
        get :search, params: default_params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1
        payment = payments.first
        expect(payment[:over_due_payment]).to eq false
        expect(payment[:installments].first[:over_due_installment]).to eq false
      end
    end

    describe 'over_due_only' do
      before do
        # not over due
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor,
          due_ymd: '20190101', paid_up_ymd: '20190101')
        FactoryBot.create(:installment, order: order, payment: payment, paid_up_ymd: '20190101')

        # over due
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor,
          due_ymd: '20190101', paid_up_ymd: '20190102')
        FactoryBot.create(:installment, order: order, payment: payment, paid_up_ymd: '20190102')
      end

      it '遅延したpaymentのみが取得できること' do
        params = default_params
        params[:search][:over_due_only] = true

        get :search, params: default_params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1
        payment = payments.first
        expect(payment[:over_due_payment]).to eq true
        expect(payment[:installments].first[:over_due_installment]).to eq true
      end
    end

    describe 'used_cashback_only' do
      before do
        # paid_cashback あり
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor, paid_cashback: 100.0)
        FactoryBot.create(:installment, order: order, payment: payment)

        # paid_cashback なし
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        payment = FactoryBot.create(:payment, :paid, contractor: contractor, paid_cashback:   0.0)
        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it 'cashbackを使用したpaymentのみが取得できること' do
        params = default_params
        params[:search][:used_cashback_only] = true

        get :search, params: default_params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1
        expect(payments.first[:cashback]).to eq 100.0
      end
    end
  end

  describe '#order_detail' do
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

    before do
      payment = FactoryBot.create(:payment, :paid, contractor: contractor)
      FactoryBot.create(:installment, order: order, payment: payment)
    end

    it '正常に値が取得できること' do
      params = {
        auth_token: auth_token.token,
        order_id: order.id
      }
      get :order_detail, params: params

      expect(res[:success]).to eq true
      expect(res[:order][:order_number]).to eq order.order_number
    end
  end

  describe 'exemption_late_charge' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
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
      }.dup
    }

    before do
      FactoryBot.create(:business_day, business_ymd: '20190116')
    end

    context '免除なし' do
      before do
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)

        payment = FactoryBot.create(:payment, :paid, contractor: contractor,
          due_ymd: '20190115', paid_up_ymd: '20190116',
          total_amount: 1100.0, paid_total_amount: 1110.0)

        FactoryBot.create(:installment, order: order, payment: payment,
          due_ymd: '20190115', paid_up_ymd: '20190116',
          principal: 1000.0, interest: 100.0,
          paid_principal: 1000.0, paid_interest: 100.0, paid_late_charge: 10.0)
      end

      it 'late_chargeがpaid_late_chargeと同じになること' do
        get :search, params: default_params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1

        payment = payments.first
        expect(payment[:over_due_payment]).to eq true

        installment = payment[:installments].first
        expect(installment[:over_due_installment]).to eq true

        # Paid late charge と同じになること
        expect(installment[:late_charge]).to eq 10.0
      end
    end

    context 'すべて免除' do
      before do
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)

        payment = FactoryBot.create(:payment, :paid, contractor: contractor,
          due_ymd: '20190115', paid_up_ymd: '20190116',
          total_amount: 1100.0, paid_total_amount: 1100.0)

        installment = FactoryBot.create(:installment, order: order, payment: payment,
          due_ymd: '20190115', paid_up_ymd: '20190116',
          principal: 1000.0, interest: 100.0,
          paid_principal: 1000.0, paid_interest: 100.0, paid_late_charge: 0.0)

        FactoryBot.create(:exemption_late_charge, installment: installment, amount: 10.0)
      end

      it 'late_chargeが0.0になること' do
        get :search, params: default_params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1

        payment = payments.first
        expect(payment[:over_due_payment]).to eq true

        installment = payment[:installments].first
        expect(installment[:over_due_installment]).to eq true

        # Paid late charge と同じになること
        expect(installment[:late_charge]).to eq 0.0
      end
    end

    context '一部遅損金支払い、一部免除' do
      before do
        order = FactoryBot.create(:order, :inputed_date, contractor: contractor)

        payment = FactoryBot.create(:payment, :paid, contractor: contractor,
          due_ymd: '20190115', paid_up_ymd: '20190116',
          total_amount: 1100.0, paid_total_amount: 1110.0)

        installment = FactoryBot.create(:installment, order: order, payment: payment,
          due_ymd: '20190115', paid_up_ymd: '20190116',
          principal: 1000.0, interest: 100.0,
          paid_principal: 1000.0, paid_interest: 100.0, paid_late_charge: 10.0)

        FactoryBot.create(:exemption_late_charge, installment: installment, amount: 20.0)
      end

      it 'late_chargeが0.0になること' do
        get :search, params: default_params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1

        payment = payments.first
        expect(payment[:over_due_payment]).to eq true

        installment = payment[:installments].first
        expect(installment[:over_due_installment]).to eq true

        # Paid late charge と同じになること
        expect(installment[:late_charge]).to eq 0.0
      end
    end
  end
end
