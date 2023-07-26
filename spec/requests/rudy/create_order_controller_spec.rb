require 'rails_helper'

RSpec.describe Rudy::CreateOrderController, type: :request do

  describe "POST #call" do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { Dealer.first }
    let(:second_dealer) { FactoryBot.create(:dealer)}
    let(:contractor) {
      FactoryBot.create(:contractor, main_dealer: dealer, approval_status: "qualified")
    }
    let(:contractor_user) {
      FactoryBot.create(:contractor_user, contractor: contractor, rudy_auth_token: 'hoge')
    }
    let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

    before do
      FactoryBot.create(:cbm_dealer, area: area)

      FactoryBot.create(:business_day, business_ymd: '20190101')
      FactoryBot.create(:system_setting)
      FactoryBot.create(:rudy_api_setting)

      FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility)
      FactoryBot.create(:dealer_limit, dealer: dealer, eligibility: eligibility)
      FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user)
    end

    it "result is OK" do
      params = {
        tax_id: contractor.tax_id,
        order_number: "12345",
        product_id: 2,
        dealer_code: dealer.dealer_code,
        purchase_date: "20190102",
        amount: 1,
        auth_token: contractor_user.rudy_auth_token
      }

      post rudy_create_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'
      expect(res[:header_text]).to eq 'sample header text'
      expect(res[:text]).to eq 'sample text'
    end

    it 'Orderが正しく登録される事' do
      params = {
        tax_id: contractor.tax_id,
        order_number: "12345",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        second_dealer_code: second_dealer.dealer_code,
        purchase_date: "20190101",
        amount: 1000000,
        second_dealer_amount: 1000,
        amount_without_tax: 900000,
        region: 'sample region',
        auth_token: contractor_user.rudy_auth_token
      }

      post rudy_create_order_path, params: params, headers: headers

      expect(response).to have_http_status(:success)
      expect(res[:result]).to eq 'OK'

      expect(Order.count).to eq 1
      order = Order.first

      expect(order.order_number).to eq '12345'
      expect(order.contractor).to eq contractor
      expect(order.dealer).to eq dealer
      expect(order.second_dealer).to eq second_dealer
      expect(order.product.product_key).to eq 1
      expect(order.installment_count).to eq 1
      expect(order.purchase_ymd).to eq '20190101'
      expect(order.purchase_amount).to eq 1000000.0
      expect(order.amount_without_tax).to eq 900000.0
      expect(order.second_dealer_amount).to eq 1000.0
      expect(order.paid_up_ymd).to eq nil
      expect(order.input_ymd).to eq nil
      expect(order.input_ymd_updated_at).to eq nil
      expect(order.order_user).to eq contractor_user
      expect(order.region).to eq 'sample region'
    end

    it "スケジュールが業務日で作成されること" do
      params = {
        tax_id: contractor.tax_id,
        order_number: "12345",
        product_id: 2,
        dealer_code: dealer.dealer_code,
        purchase_date: "20191231",
        amount: 1000000,
        auth_token: contractor_user.rudy_auth_token
      }

      post rudy_create_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      order = contractor.orders.find_by(order_number: "12345")
      payments = order.payments
      expect(payments.first.due_ymd).to eq '20190215'
      expect(payments.second.due_ymd).to eq '20190315'
      expect(payments.third.due_ymd).to eq '20190415'
    end

    describe 'バリデーションチェック' do
      it '同じDealerで同じorder_numberが登録できないこと' do
        FactoryBot.create(:order, contractor: contractor, dealer: dealer, order_number: '12345')

        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190102",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'duplicate_order'
      end

      it '異なるDealerの同じorder_numberが登録できること' do
        dealer2 = FactoryBot.create(:dealer, area: area)
        contractor2 = FactoryBot.create(:contractor)
        FactoryBot.create(:order, contractor: contractor2, order_number: '12345')

        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190102",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token,
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'
      end

      it 'bill_dateを送っても登録されないこと' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000000,
          region: 'sample region',
          auth_token: contractor_user.rudy_auth_token,
          bill_date: "a",
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        expect(Order.count).to eq 1
        order = Order.first

        expect(order.bill_date).to eq ""
      end

      describe 'not_pdpa_agreed' do
        before do
          FactoryBot.create(:pdpa_version)
        end

        let(:default_params) {
          {
            tax_id: contractor.tax_id,
            order_number: "12345",
            product_id: 1,
            dealer_code: dealer.dealer_code,
            purchase_date: "20190102",
            amount: 10000,
            auth_token: contractor_user.rudy_auth_token
          }
        }

        it '同意なしでエラーになること' do
          post rudy_create_order_path, params: default_params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'not_pdpa_agreed'
        end

        context '同意あり' do
          before do
            contractor_user.create_latest_pdpa_agreement!
          end

          it 'エラーにならないこと' do
            post rudy_create_order_path, params: default_params, headers: headers

            expect(res[:result]).to eq 'OK'
          end
        end
      end

      it 'processing・qualified 以外のContractorは対象外' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190102",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }

        # pre_registration
        contractor.pre_registration!
        post rudy_create_order_path, params: params, headers: headers
        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'contractor_not_found'

        # rejected
        contractor.rejected!
        post rudy_create_order_path, params: params, headers: headers
        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'contractor_not_found'

        # processing
        contractor.processing!
        post rudy_create_order_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'
      end
    end

    describe 'Installment' do
      it '分割1回が正しく登録されること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        expect(Order.count).to eq 1
        order = Order.first

        installments = order.installments
        expect(installments.count).to eq 1

        installment = installments.first

        expect(installment.payment.due_ymd).to eq '20190215'
        expect(installment.payment.contractor).to eq contractor
        expect(installment.installment_number).to eq 1
        expect(installment.due_ymd).to eq '20190215'
        expect(installment.paid_up_ymd).to eq nil
        expect(installment.principal).to eq 1000000.0
        expect(installment.interest).to eq 0.0
        expect(installment.paid_principal).to eq 0.0
        expect(installment.paid_interest).to eq 0.0
        expect(installment.paid_late_charge).to eq 0.0
      end

      it '分割3回が正しく登録されること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        expect(Order.count).to eq 1
        order = Order.first

        installments = order.installments
        expect(installments.count).to eq 3

        installment1 = installments.first
        expect(installment1.installment_number).to eq 1
        expect(installment1.due_ymd).to eq '20190215'
        expect(installment1.principal).to eq 333_333.34
        expect(installment1.interest).to eq 8366.68

        installment2 = installments.second
        expect(installment2.installment_number).to eq 2
        expect(installment2.due_ymd).to eq '20190315'
        expect(installment2.principal).to eq 333_333.33
        expect(installment2.interest).to eq 8366.66

        installment3 = installments.third
        expect(installment3.installment_number).to eq 3
        expect(installment3.due_ymd).to eq '20190415'
        expect(installment3.principal).to eq 333_333.33
        expect(installment3.interest).to eq 8366.66
      end
    end

    describe 'Payment' do
      it '全てのPaymentを新規作成' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        payments = contractor.include_no_input_date_payments
        expect(payments.count).to eq 3
        expect(payments.all?{|payment| payment.status == 'not_due_yet'}).to eq true

        expect(Order.count).to eq 1
        order = Order.first

        installments = order.installments
        expect(installments.count).to eq 3

        installment1 = installments.first
        installment2 = installments.second
        installment3 = installments.third

        payment1 = installment1.payment
        payment2 = installment2.payment
        payment3 = installment3.payment

        expect(payment1.due_ymd).to eq '20190215'
        expect(payment1.total_amount).to eq 341_700.02

        expect(payment2.due_ymd).to eq '20190315'
        expect(payment2.total_amount).to eq 341_699.99

        expect(payment3.due_ymd).to eq '20190415'
        expect(payment3.total_amount).to eq 341_699.99
      end

      it '2回注文、一部のPaymentは新規、一部は更新' do
        # 1回目の注文
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }
        post rudy_create_order_path, params: params, headers: headers
        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        order = Order.first
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          dealer_code: dealer.dealer_code,
          input_date: "20190101"
        }
        post rudy_set_order_input_date_path, params: params, headers: headers

        Batch::Daily.exec(to_ymd: '20190201')

        # 2回目の注文
        params = {
          tax_id: contractor.tax_id,
          order_number: "23456",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190201",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }
        post rudy_create_order_path, params: params, headers: headers
        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        expect(contractor.include_no_input_date_payments.count).to eq 4

        expect(Order.count).to eq 2

        order1 = Order.first
        order2 = Order.second

        installments1 = order1.installments
        installments2 = order2.installments

        expect(installments1.count).to eq 3
        expect(installments2.count).to eq 3

        # order1 のinstallments
        installment1_1 = installments1.first
        installment1_2 = installments1.second
        installment1_3 = installments1.third

        # order2 のinstallments
        installment2_1 = installments2.first
        installment2_2 = installments2.second
        installment2_3 = installments2.third

        payment1_1 = installment1_1.payment
        payment1_2 = installment1_2.payment
        payment1_3 = installment1_3.payment

        payment2_1 = installment2_1.payment
        payment2_2 = installment2_2.payment
        payment2_3 = installment2_3.payment

        # 同じPaymentのチェック
        expect(payment1_2).to eq payment2_1
        expect(payment1_3).to eq payment2_2

        # Paymentのチェック
        expect(payment1_1.due_ymd).to eq '20190215'
        expect(payment1_1.total_amount).to eq 341_700.02
        expect(payment1_1.status).to eq 'next_due'

        expect(payment1_2.due_ymd).to eq '20190315'
        # order1.installment2 と order2.installment1 の合計
        expect(payment1_2.total_amount).to eq (341_699.99 + 341_700.02)
        expect(payment1_2.status).to eq 'not_due_yet'

        expect(payment2_2.due_ymd).to eq '20190415'
        # order1.installment3 と order2.installment2 の合計
        expect(payment2_2.total_amount).to eq (341_699.99 + 341_699.99)
        expect(payment2_2.status).to eq 'not_due_yet'

        expect(payment2_3.due_ymd).to eq '20190515'
        expect(payment2_3.total_amount).to eq 341_699.99
        expect(payment2_3.status).to eq 'not_due_yet'
      end

      it '全てのPaymentを更新' do
        # 1回目の注文
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }
        post rudy_create_order_path, params: params, headers: headers
        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        # 2回目の注文
        params = {
          tax_id: contractor.tax_id,
          order_number: "23456",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190115",
          amount: 1000000,
          auth_token: contractor_user.rudy_auth_token
        }
        post rudy_create_order_path, params: params, headers: headers
        expect(response).to have_http_status(:success)
        expect(res[:result]).to eq 'OK'

        expect(contractor.include_no_input_date_payments.count).to eq 3
      end
    end

    describe 'Product4' do
      let(:product4) { Product.find_by(product_key: 4) }

      it '正常に購入されること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 4,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers
        contractor.reload

        expect(res[:result]).to eq 'OK'

        order = contractor.orders.first
        expect(order.installment_count).to eq 1
        expect(order.product).to eq product4

        installment = order.installments.first
        expect(installment.due_ymd).to eq '20190315'
        expect(installment.principal).to eq 1000.0
        expect(installment.interest).to eq 24.6

        payment = installment.payment
        expect(payment.due_ymd).to eq '20190315'
        expect(payment.total_amount).to eq 1024.6
      end
    end

    describe '15日商品' do
      let(:product8) { Product.find_by(product_key: 8) }
      let(:dealer) { FactoryBot.create(:permsin_dealer) }

      before do
        FactoryBot.create(:dealer_type_limit, :permsin, eligibility: eligibility)
        FactoryBot.create(:terms_of_service_version, :permsin, contractor_user: contractor_user)
      end

      it '正常に購入されること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: product8.product_key,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190101",
          amount: 1000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers
        contractor.reload

        expect(res[:result]).to eq 'OK'

        payment = contractor.include_no_input_date_payments.last
        expect(payment.not_due_yet?).to eq true
        expect(payment.due_ymd).to eq '20190131'
      end

      context '30日商品あり' do
        before do
          payment = FactoryBot.create(:payment, :next_due, due_ymd: '20190131', contractor: contractor)
          order = FactoryBot.create(:order, input_ymd: '20181230', contractor: contractor)
          FactoryBot.create(:installment, order: order, payment: payment, contractor: contractor)
        end

        it 'ステータスがnext_dueのままであること' do
          params = {
            tax_id: contractor.tax_id,
            order_number: "12345",
            product_id: product8.product_key,
            dealer_code: dealer.dealer_code,
            purchase_date: "20190101",
            amount: 1000,
            auth_token: contractor_user.rudy_auth_token
          }

          post rudy_create_order_path, params: params, headers: headers
          contractor.reload

          expect(res[:result]).to eq 'OK'

          expect(contractor.payments.count).to eq 1
          payment = contractor.payments.first
          expect(payment.next_due?).to eq true
          expect(payment.due_ymd).to eq '20190131'

          # InputDateを入れても変わらないこと
          set_input_date(contractor, '12345', dealer, '20190101')
          payment.reload
          expect(payment.next_due?).to eq true
        end
      end
    end

    describe 'over dealer limit' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        contractor.latest_dealer_type_limits.first.update!(limit_amount: 3000)
        contractor.latest_dealer_limits.first.update!(limit_amount: 2000)
      end

      it 'available_balanceが返却されること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190102",
          amount: 2500,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_limit'
        expect(res[:available_balance]).to eq 2000
      end
    end

    describe 'over dealer type limit' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        contractor.latest_dealer_type_limits.first.update!(limit_amount: 3000)
        contractor.latest_dealer_limits.first.update!(limit_amount: 5000)
      end

      it 'available_balanceが返却されること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 2,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190102",
          amount: 4000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_type_limit'
        expect(res[:available_balance]).to eq 3000
      end
    end

    describe '規約同意' do
      before do
        contractor_user.agreed_terms_of_services.destroy_all
      end

      it '規約に同意していない場合はnot_agreedのエラーが返ること' do
        params = {
          tax_id: contractor.tax_id,
          order_number: "12345",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: "20190102",
          amount: 10000,
          auth_token: contractor_user.rudy_auth_token
        }

        post rudy_create_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'not_agreed'
      end
    end

    it "日付不正でエラーになること" do
      params = {
        tax_id: contractor.tax_id,
        order_number: "12345",
        product_id: 2,
        dealer_code: dealer.dealer_code,
        purchase_date: "2019102",
        amount: 1000000,
        auth_token: contractor_user.rudy_auth_token
      }

      post rudy_create_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'invalid_purchase_date'
    end

    it 'region文字数超過エラーになること' do
      params = {
        tax_id: contractor.tax_id,
        order_number: "12345",
        product_id: 2,
        dealer_code: dealer.dealer_code,
        purchase_date: "20190102",
        amount: 10,
        region: 'a' * 51,
        auth_token: contractor_user.rudy_auth_token
      }

      post rudy_create_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'too_long_region'
    end
  end

  describe "demo" do
    it 'デモ用のトークンでデモ用レスポンスが返ること' do
      params = {
        tax_id: '1234567890111',
        order_number: '1234500000'
      }

      post rudy_create_order_path, params: params, headers: demo_token_headers
      expect(res[:result]).to eq "OK"
    end
  end
end
