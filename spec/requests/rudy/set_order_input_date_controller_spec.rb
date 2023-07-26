require 'rails_helper'

RSpec.describe Rudy::SetOrderInputDateController, type: :request do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20220717')
    FactoryBot.create(:rudy_api_setting)
    FactoryBot.create(:order, contractor: contractor)
  end

  describe "#call" do
    let(:order) { Order.first }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        order_number: order.order_number,
        dealer_code: order.dealer.dealer_code,
        input_date: ""
      }
    }

    context '正常値' do
      it '正しくレスポンスが返ること' do
        params = default_params.dup
        params[:input_date] = "20220717"

        post rudy_set_order_input_date_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"
      end
    end

    context 'project_financeのオーダー' do
      let(:project_order) { FactoryBot.create(:order, :project) }
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          order_number: project_order.order_number,
          dealer_code: project_order.dealer.dealer_code,
          input_date: "20220717"
        }
      }

      before do
        FactoryBot.create(:installment, order: project_order, payment: nil)
      end

      it 'エラーにならないこと' do
        params = default_params.dup

        post rudy_set_order_input_date_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"
      end

      describe 'Exceeded/Cashbackの自動消し込み' do
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

        it '自動消し込みが実行されないこと' do
          post rudy_set_order_input_date_path, params: default_params, headers: headers

          expect(res[:result]).to eq "OK"
          expect(contractor.receive_amount_histories.count).to eq 0
          expect(MailSpool.receive_payment.count).to eq 0
        end
      end
    end

    describe 'バリデーションチェック' do
      it '業務日以外で input_date_not_today が返ること' do
        # 業務日の前日
        params = default_params.dup
        params[:input_date] = "20220716"
        post rudy_set_order_input_date_path, params: params, headers: headers
        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "input_date_not_today"

        # 業務日の翌日
        params[:input_date] = "20220718"
        post rudy_set_order_input_date_path, params: params, headers: headers
        expect(res[:result]).to eq "NG"
        expect(res[:error]).to eq "input_date_not_today"
      end
    end

    context 'ContractorがInactive' do
      let(:params) {
        params = default_params.dup
        params[:input_date] = "20220717"
        params
      }

      before do
        contractor.inactive!
      end

      context 'purchase_ymdが期日 内' do
        let(:order) { FactoryBot.create(:order, purchase_ymd: '20220617') }

        it '可能' do
          post rudy_set_order_input_date_path, params: params, headers: headers

          expect(res[:result]).to eq "OK"
        end
      end

      context 'purchase_ymdが期日 外' do
        let(:order) { FactoryBot.create(:order, purchase_ymd: '20220616') }

        it '不可能' do
          post rudy_set_order_input_date_path, params: params, headers: headers

          expect(res[:result]).to eq "NG"
          expect(res[:error]).to eq "not_allowed_to_input"
        end
      end
    end
  end

  describe "demo" do
    it 'デモ用のトークンでデモ用レスポンスが返ること' do
      params = {
        tax_id: '1234567890111',
        order_number: '1234500000'
      }

      post rudy_set_order_input_date_path, params: params, headers: demo_token_headers
      expect(res[:result]).to eq "OK"
    end
  end

  describe 'payment.statusの検証' do
    let(:order) { FactoryBot.create(:order, :product_key8, purchase_ymd: '20220716') }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        order_number: order.order_number,
        dealer_code: order.dealer.dealer_code,
        input_date: ""
      }
    }

    context '既存のPaid Payment(Product1のオーダー)あり' do
      before do
        payment = FactoryBot.create(:payment, :paid, due_ymd: '20220815', paid_up_ymd: '20220716',
          contractor: contractor)

        # product 1
        FactoryBot.create(:installment, payment: payment,
          order: FactoryBot.create(:order, :inputed_date, purchase_ymd: '20220715')
        )

        # product 8
        FactoryBot.create(:installment, payment: payment, order: order, paid_up_ymd: nil)
      end

      it 'Paidに15日商品を追加した場合はstatusがnext_dueになること' do
        params = default_params.dup
        params[:input_date] = "20220717"

        post rudy_set_order_input_date_path, params: params, headers: headers

        expect(res[:result]).to eq "OK"

        expect(Payment.count).to eq 1
        payment = Payment.first
        expect(payment.paid?).to eq false
        expect(payment.paid_up_ymd).to eq nil
      end
    end
  end

  describe 'Exceeded/Cashbackの自動消し込み' do
    let(:order) { Order.first }
    let(:default_params) {
      {
        tax_id: contractor.tax_id,
        order_number: order.order_number,
        dealer_code: order.dealer.dealer_code,
        input_date: "20220717"
      }
    }

    context '同じPayment' do
      before do
        JvService::Application.config.auto_repayment_exceeded_and_cashback = true

        payment = FactoryBot.create(:payment, :next_due, due_ymd: '20221015', contractor: contractor)

        # 支払い済みOrder
        paid_order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        FactoryBot.create(:installment,
          payment: payment,
          order: paid_order,
          due_ymd: payment.due_ymd, principal: 100, paid_principal: 100
        )

        FactoryBot.create(:installment,
          payment: payment,
          order: FactoryBot.create(:order, :inputed_date, contractor: contractor),
          due_ymd: payment.due_ymd, principal: 100,
        )

        FactoryBot.create(:installment,
          payment: payment,
          order: order,
          due_ymd: payment.due_ymd, principal: 100,
        )

        FactoryBot.create(:cashback_history, :gain, :latest, order: paid_order, cashback_amount: 100)
      end

      it 'Cashbackは同じPaymentなので自動消し込みが実行されないこと' do
        post rudy_set_order_input_date_path, params: default_params, headers: headers

        expect(res[:result]).to eq "OK"
        expect(contractor.receive_amount_histories.count).to eq 0
        expect(MailSpool.receive_payment.count).to eq 0
      end
    end

    context '異なるPaymentがある' do
      before do
        JvService::Application.config.auto_repayment_exceeded_and_cashback = true

        payment = FactoryBot.create(:payment, :next_due, due_ymd: '20220930', contractor: contractor)

        # 支払い済みOrder
        paid_order = FactoryBot.create(:order, :inputed_date, contractor: contractor)
        FactoryBot.create(:installment,
          payment: payment,
          order: paid_order,
          due_ymd: payment.due_ymd, principal: 100, paid_principal: 100
        )

        # 未払いOrder
        FactoryBot.create(:installment,
          payment: payment,
          order: FactoryBot.create(:order, :inputed_date, contractor: contractor),
          due_ymd: payment.due_ymd, principal: 100,
        )

        # InputDate対象のオーダー
        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :not_due_yet, due_ymd: '20221015', contractor: contractor),
          order: order,
          due_ymd: payment.due_ymd, principal: 100,
        )

        FactoryBot.create(:cashback_history, :gain, :latest, order: paid_order, cashback_amount: 100)
      end

      it '自動消し込みが実行され ない こと(次のPaymentが消し込み可能でもPaymentに消し込みができなくなった時点でループから抜けるので消し込みはされない)' do
        post rudy_set_order_input_date_path, params: default_params, headers: headers

        expect(res[:result]).to eq "OK"
        expect(contractor.receive_amount_histories.count).to eq 0
        expect(MailSpool.receive_payment.count).to eq 0
      end

      context '環境設定で機能をOFFへ' do
        before do
          JvService::Application.config.auto_repayment_exceeded_and_cashback = false
        end

        it '自動消し込みが実行されないこと' do
          post rudy_set_order_input_date_path, params: default_params, headers: headers

          expect(res[:result]).to eq "OK"
          expect(contractor.receive_amount_histories.count).to eq 0
          expect(MailSpool.receive_payment.count).to eq 0
        end
      end
    end

    context 'paidのPaymentがある' do
      before do
        JvService::Application.config.auto_repayment_exceeded_and_cashback = true

        paid_order = FactoryBot.create(:order, :inputed_date, contractor: contractor, paid_up_ymd: '20220930')

        # 支払い済みPayment
        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :paid, due_ymd: '20220930', contractor: contractor),
          order: paid_order,
          due_ymd: '20220930', principal: 100, paid_principal: 100, paid_up_ymd: '20220930'
        )

        # InputDate対象のオーダー
        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :not_due_yet, due_ymd: '20221015', contractor: contractor),
          order: order,
          due_ymd: '20221015', principal: 100,
        )

        FactoryBot.create(:cashback_history, :gain, :latest, order: paid_order, cashback_amount: 1.23)
      end

      it 'メールが送信されること' do
        post rudy_set_order_input_date_path, params: default_params, headers: headers

        expect(res[:result]).to eq "OK"
        expect(contractor.receive_amount_histories.count).to eq 1
        expect(MailSpool.receive_payment.count).to eq 1
        expect(MailSpool.receive_payment.first.mail_body.include?("1.23")).to eq true
      end

      context '環境設定で機能をOFFへ' do
        before do
          JvService::Application.config.auto_repayment_exceeded_and_cashback = false
        end

        it '自動消し込みが実行されないこと' do
          post rudy_set_order_input_date_path, params: default_params, headers: headers

          expect(res[:result]).to eq "OK"
          expect(contractor.receive_amount_histories.count).to eq 0
          expect(MailSpool.receive_payment.count).to eq 0
        end
      end
    end
  end
end
