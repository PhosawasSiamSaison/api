require 'rails_helper'

RSpec.describe Contractor::PaymentStatusController, type: :controller do
  before do
    FactoryBot.create(:system_setting)
  end

  let(:contractor) { contractor_user.contractor }
  let(:contractor_user) { FactoryBot.create(:contractor_user)}
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: contractor_user).token }

  describe "GET #payments" do
    let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102') }
    let(:payment) { FactoryBot.create(:payment, :next_due, contractor: contractor,
      due_ymd: '20190215', total_amount: 100.0, paid_total_amount: 10.0) }

    before do
      FactoryBot.create(:business_day)
      installment = FactoryBot.create(:installment, order: order, payment: payment,
        due_ymd: '20190215', principal: 100.0, interest: 0.0,
        paid_principal: 10.0, paid_interest: 0.0)

      InstallmentHistory.first.update!(to_ymd: '20190130')
      InstallmentHistory.create(installment: installment, from_ymd: '20190131',
        paid_principal: 10.0, paid_interest: 0.0, paid_late_charge: 0.0)
    end

    it "正常に取得ができること" do
      params = {
        auth_token: auth_token
      }

      get :payments, params: params
      expect(response).to have_http_status(:success)
      expect(res[:success]).to eq true
      expect(res.has_key?(:allowed_change_products)).to eq true

      payment = res[:payments].first
      expect(payment.has_key?(:id)).to eq true
      expect(payment.has_key?(:due_ymd)).to eq true
      expect(payment.has_key?(:paid_up_ymd)).to eq true
      expect(payment.has_key?(:total_amount)).to eq true
      expect(payment.has_key?(:paid_total_amount)).to eq true
      expect(payment.has_key?(:status)).to eq true
      expect(payment.has_key?(:can_apply_change_product)).to eq true
    end

    context 'input_ymd未入力のorderのpaymentあり' do
      let(:order2) { FactoryBot.create(:order, contractor: contractor) }
      let(:payment2) { FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315') }

      before do
        FactoryBot.create(:installment, order: order2, payment: payment2)
      end

      it 'input_ymdがないpaymentが取得できないこと' do
        params = {
          auth_token: auth_token
        }

        get :payments, params: params
        expect(response).to have_http_status(:success)
        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 1
      end
    end

    context '支払い済みでexceededの使用paymentあり' do
      let(:order2) {
        FactoryBot.create(:order, contractor: contractor, input_ymd: '20181215')
      }
      let(:payment2) { FactoryBot.create(:payment, :paid, contractor: contractor,
        due_ymd: '20190115', paid_up_ymd: '20190101', total_amount: 100.0,
        paid_total_amount: 100.0, paid_exceeded: 100.0, paid_cashback: 0.0) }

      before do
        BusinessDay.update!(business_ymd: '20190131')
        FactoryBot.create(:installment, order: order2, payment: payment2,
          principal: 100.0, paid_principal: 100.0, interest: 0.0, paid_interest: 0.0)
      end

      it 'total_amountが正しいこと' do
        params = {
          auth_token: auth_token,
          include_paid: true,
        }

        get :payments, params: params
        expect(res[:success]).to eq true
        expect(res[:payments].count).to eq 2

        paid_payment = Payment.find_by(status: :paid)
        next_payment = Payment.find_by(status: :next_due)

        expect(paid_payment.status).to eq 'paid'
        expect(next_payment.status).to eq 'next_due'

        payment1 = res[:payments].first
        payment2 = res[:payments].last

        expect(payment1[:status]).to eq 'next_due'
        expect(payment2[:status]).to eq 'paid'

        expect(payment1[:total_amount]).to eq 90.0
        expect(payment2[:total_amount]).to eq 0.0
      end
    end
  end
end
