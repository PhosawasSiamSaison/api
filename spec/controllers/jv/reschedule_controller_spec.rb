require 'rails_helper'

RSpec.describe Jv::RescheduleController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:order) { Order.first }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20200101')
  end

  describe 'contractor' do
    it '正常に値が取得できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
      }

      get :contractor, params: params
      expect(res[:success]).to eq true
    end
  end

  describe 'reschedule_total_amount' do
    it 'order_idsの引数なしで正常に値が取得できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        exec_ymd: '20200101',
      }

      get :reschedule_total_amount, params: params
      expect(res[:success]).to eq true
    end

    context '複数のorderを指定' do
      let(:order1) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }
      let(:order2) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          exec_ymd: '20200101',
          order_ids: [order1.id, order2.id],
        }

        get :reschedule_total_amount, params: params
        expect(res[:success]).to eq true
      end
    end
  end

  describe 'order_list' do
    context '再約定できるオーダー' do
      before do
        FactoryBot.create(:order, :inputed_date, contractor: contractor)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          exec_ymd: '20200101',
        }

        get :order_list, params: params
        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1
        order = res[:orders].first
        expect(order[:can_reschedule]).to eq true
      end
    end

    context '取得できるが再約定できないオーダー' do
      before do
        FactoryBot.create(:order, :inputed_date, :applied_change_product, contractor: contractor)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          exec_ymd: '20200101',
        }

        get :order_list, params: params
        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 1
        order = res[:orders].first
        expect(order[:can_reschedule]).to eq false
      end
    end

    context '取得されないオーダー' do
      before do
        # Input Dateなし
        FactoryBot.create(:order, contractor: contractor)
        # キャンセル済み
        FactoryBot.create(:order, :inputed_date, :canceled, contractor: contractor)
        # 支払済
        FactoryBot.create(:order, :inputed_date, :paid, contractor: contractor)
        # FeeOrder
        FactoryBot.create(:order, :inputed_date, :fee_order, contractor: contractor)
      end

      it '正常に値が取得できること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          exec_ymd: '20200101',
        }

        get :order_list, params: params
        expect(res[:success]).to eq true
        expect(res[:orders].count).to eq 0
      end
    end
  end

  describe 'confirmation' do
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }
    let(:rescheduled_order) {
      FactoryBot.create(:order, :inputed_date, contractor: contractor,
        rescheduled_new_order_id: FactoryBot.create(:order).id)
    }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        exec_ymd: '20200101',
        reschedule_order_count: 1,
        fee_order_count: 1,
        no_interest: false,
        order_ids: [order.id],
      }
    }

    it '正常に値が取得できること' do
      params = default_params.dup

      get :confirmation, params: params
      expect(res[:success]).to eq true
    end

    it 'reschedule_order_countとfee_order_countの引数なしで値を0で取得できること' do
      params = default_params.dup
      params.delete(:reschedule_order_count)
      params.delete(:fee_order_count)

      get :confirmation, params: params
      expect(res[:success]).to eq true

      expect(res[:new_order_installments][:count]).to eq 0
      expect(res[:new_order_installments][:schedule]).to eq []
      expect(res[:new_order_installments][:total_amount]).to eq 0.0

      expect(res[:fee_order_installments][:count]).to eq 0
      expect(res[:fee_order_installments][:schedule]).to eq []
      expect(res[:fee_order_installments][:total_amount]).to eq 0.0

      expect(res[:total_installments][:count]).to eq 0
      expect(res[:total_installments][:schedule]).to eq []
      expect(res[:total_installments][:total_amount]).to eq 0.0
    end

    it '再約定できないオーダーを指定して排他エラーが返ること' do
      params = default_params.dup
      params[:order_ids] = [rescheduled_order.id]

      get :confirmation, params: params
      expect(res[:success]).to eq false
      expect(res[:error]).to eq "record_not_found"
    end
  end

  describe 'register' do
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
    let(:order) {
      FactoryBot.create(:order, contractor: contractor, input_ymd: '20200101')
    }
    let(:default_params) {
      {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        exec_ymd: '20200101',
        reschedule_order_count: 1,
        fee_order_count: 1,
        no_interest: true,
        order_ids: [order.id],
      }
    }

    before do
      payment = FactoryBot.create(:payment, due_ymd: 20200215, total_amount: 100)

      FactoryBot.create(:installment, order: order, payment: payment,
        principal: 100, interest: 0, due_ymd: 20200215)
    end

    it '正常に処理されること' do
      params = default_params.dup

      post :register, params: params

      expect(res[:success]).to eq true
    end

    context 'JvUserの権限なし' do
      before do
        jv_user.staff!
      end

      it 'エラーが返ること' do
        params = default_params.dup

        post :register, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["You do not have permission to perform operations"]
      end
    end

    describe '引数チェック' do
      it 'reschedule_order_countが0でエラーになること' do
        params = default_params.dup
        params[:reschedule_order_count] = 0

        post :register, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq ["Reschedule Order count is invalid."]
      end

      it 'fee_order_countが0かつfee_orderの金額が0でエラーにならないこと' do
        params = default_params.dup
        params[:fee_order_count] = 0

        post :register, params: params

        expect(res[:success]).to eq true
      end

      context 'fee orderの支払いあり' do
        let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

        before do
          FactoryBot.create(:installment, order: order, principal: 100, interest: 1)
        end

        it 'fee_order_countが0でエラーになること' do
          params = default_params.dup
          params[:fee_order_count] = 0

          post :register, params: params
          expect(res[:success]).to eq false
          expect(res[:errors]).to eq ["Fee Order count is invalid."]
        end
      end
    end

    describe 'paymentがpaidになるパターンのチェック' do
      let(:payment) { Payment.find_by(due_ymd: '20200215') }
      let(:order2) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20200101') }
      let(:order3) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20200101') }

      before do
        BusinessDay.update!(business_ymd: '20200201')

        FactoryBot.create(:installment, order: order2, payment: payment,
          principal: 200, interest: 0, due_ymd: 20200215)

        FactoryBot.create(:installment, order: order3, payment: payment,
          principal: 400, interest: 0, due_ymd: 20200215)

        # order1を支払い完了へ
        order.update!(paid_up_ymd: '20200201')
        order.installments.first.update!(paid_up_ymd: '20200201', paid_principal: 100)

        payment.update!(status: :next_due, total_amount: 700, paid_total_amount: 100)
      end

      it '支払い済みのinstallmentがあり、他を全て再約定した場合(異なる期限で)、paymentがpaidになること' do
        params = default_params.dup
        params[:fee_order_count] = 0
        params[:order_ids] = [order2.id, order3.id]

        post :register, params: params

        expect(res[:success]).to eq true

        expect(payment.reload.status).to eq 'paid'
      end
    end

    xdescribe 'set limit zero' do
      before do

      end

      it 'set_credit_limit_to_zeroがfalseでlimitが0にならないこと' do
        params = default_params.dup
        params[:set_credit_limit_to_zero] = false

        post :register, params: params
        expect(res[:success]).to eq true


      end
    end
  end

  describe 'order_detail' do
    let(:order) { FactoryBot.create(:order, :inputed_date, contractor: contractor) }

    it '正常に値が取得できること' do
      params = {
        auth_token: auth_token.token,
        order_id: order.id,
      }

      get :order_detail, params: params
      expect(res[:success]).to eq true
    end
  end
end
