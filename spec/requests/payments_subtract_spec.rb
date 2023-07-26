require 'rails_helper'

RSpec.describe "PaymentsSubtract", type: :request do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:contractor_user) { FactoryBot.create(:contractor_user) }
  let(:contractor) { contractor_user.contractor }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:cbm_dealer) { FactoryBot.create(:cbm_dealer) }
  let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)

    FactoryBot.create(:dealer_type_limit, :cbm, eligibility: eligibility, limit_amount: 99999999999)
    FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: cbm_dealer, limit_amount: 99999999999)
    FactoryBot.create(:terms_of_service_version, :cbm, contractor_user: contractor_user)
  end

  describe '基本' do
    before do
      jv_user.auth_tokens.create!(token: 'hoge')
      contractor_user.auth_tokens.create!(token: 'fuga')

      # 認証
      params = {
        tax_id: contractor.tax_id,
        username: contractor_user.user_name,
        one_time_passcode: "123456"
      }
      post rudy_verify_account_path, params: params, headers: headers
      raise if res[:result] != "OK"

      @auth_token = res[:auth_token]
      # 削除される一時パスコードを戻す（次の注文のため)
      contractor_user.reload.update!(rudy_passcode: '123456')

      # 注文
      params = {
        tax_id: contractor.tax_id,
        order_number: "1",
        product_id: product2.product_key,
        dealer_code: cbm_dealer.dealer_code,
        purchase_date: "20190101",
        amount: "1000000.00",
        auth_token: @auth_token
      }
      post rudy_create_order_path, params: params, headers: headers
      raise if res[:result] != "OK"

      # 配送
      params = {
        tax_id: contractor.tax_id,
        order_number: "1",
        dealer_code: cbm_dealer.dealer_code,
        input_date: "20190101"
      }
      post rudy_set_order_input_date_path, params: params, headers: headers
      raise if res[:result] != "OK"
    end

    context 'input_date入力ありOrder' do
      context 'cashback: 0, exceeded: 0' do
        it '適用されないこと' do
          # JV Payment List
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          payment3 = res[:payments].third
          expect(payment3[:exceeded]).to eq 0
          expect(payment3[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 341700.02

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341700.02
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 341700.02
        end
      end

      context 'cashback: 341700.02, exceeded: 0' do
        before do
          contractor.create_gain_cashback_history(341700.02, '20190101', 0)
        end

        it 'cashbackが適用されること' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 341700.02

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 341700.02
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0
        end
      end

      context 'cashback: 0, exceeded: 341700.02' do
        before do
          contractor.update!(pool_amount: 341700.02)
        end

        it 'exceededが適用されること' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 341700.02
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 341700.02
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0
        end
      end

      context 'cashback: 0, exceeded: 341700.03' do
        before do
          contractor.update!(pool_amount: 341700.03)
        end

        it 'exceededが次のpaymentにまたがること' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 341700.02
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0.01
          expect(payment2[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.98

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 341700.02
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0

          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment2[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341699.98
          expect(payment[:due_amount]).to eq 341699.99
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 0.01
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 341699.98
        end
      end

      context 'cashback: 341700.03, exceeded: 0' do
        before do
          contractor.create_gain_cashback_history(341700.03, '20190101', 0)
        end

        it 'cashbackが次のpaymentにまたがること' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 341700.02

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0.01

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.98

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 341700.02
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0

          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment2[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341699.98
          expect(payment[:due_amount]).to eq 341699.99
          expect(payment[:cashback]).to eq 0.01
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 341699.98
        end
      end

      context '一部を支払い' do
        before do
          contractor.create_gain_cashback_history(100, '20190101', 0)
          Batch::Daily.exec(to_ymd: '20190215')

          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            payment_ymd: "20190215",
            payment_amount: 200,
            comment: "Any Comment",
            receive_amount_history_count: 0
          }
          post receive_payment_jv_payment_from_contractor_index_path, params: params
        end

        it '支払い済みのcashbackがあること' do
          # JV Payment List
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true
          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          payment3 = res[:payments].third
          expect(payment3[:exceeded]).to eq 0
          expect(payment3[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 341400.02

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params
          expect(res[:success]).to eq true

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341400.02
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 100
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 200
          expect(payment[:remaining_amount]).to eq 341400.02
        end
      end

      context '一部を支払い' do
        before do
          contractor.update!(pool_amount: 100)
          Batch::Daily.exec(to_ymd: '20190215')

          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            payment_ymd: "20190215",
            payment_amount: 200,
            comment: "Any Comment",
            receive_amount_history_count: 0
          }
          post receive_payment_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          contractor.reload.update!(pool_amount: 400)
        end

        it '支払い済みのexceededがあること' do
          # JV Payment List
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 400
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          payment3 = res[:payments].third
          expect(payment3[:exceeded]).to eq 0
          expect(payment3[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 341000.02

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341000.02
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 500
          expect(payment[:paid_total_amount]).to eq 200
          expect(payment[:remaining_amount]).to eq 341000.02
        end
      end
    end

    context 'input_date入力なしOrderを追加' do
      before do
        # input_ymdがないOrderを作成する(ありとなしのOrderで2つになる)
        # 認証
        params = {
          tax_id: contractor.tax_id,
          username: contractor_user.user_name,
          one_time_passcode: "123456"
        }
        post rudy_verify_account_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'
        @auth_token = res[:auth_token]

        # 注文
        params = {
          tax_id: contractor.tax_id,
          order_number: "2",
          product_id: product2.product_key,
          dealer_code: cbm_dealer.dealer_code,
          purchase_date: "20190101",
          amount: "1000000.00",
          auth_token: @auth_token
        }
        post rudy_create_order_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'
        expect(contractor.orders.count).to eq 2
      end

      context 'cashback: 0, exceeded: 0' do
        it '適用されないこと' do
          # JV Payment List
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          payment3 = res[:payments].third
          expect(payment3[:exceeded]).to eq 0
          expect(payment3[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 341700.02

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341700.02
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 341700.02
        end
      end

      context 'cashback: 341700.02, exceeded: 0' do
        before do
          contractor.create_gain_cashback_history(341700.02, '20190101', 0)
        end

        it 'cashbackが適用されること' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 341700.02

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 341700.02
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0
        end
      end

      context 'cashback: 0, exceeded: 341700.02' do
        before do
          contractor.update!(pool_amount: 341700.02)
        end

        it 'exceededが適用されること' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 341700.02
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 341700.02
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0
        end
      end

      context 'cashback: 0, exceeded: 341700.03' do
        before do
          contractor.update!(pool_amount: 341700.03)
        end

        # JV画面
        it 'exceededが次のpaymentにまたがる こと' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 341700.02 # input_ymdがないorderは充当の対象にしなくていい
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0.01
          expect(payment2[:cashback]).to eq 0
        end

        # Contractor画面
        it 'exceededが次のpaymentにまたがること' do
          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.98

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 341700.02
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0

          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment2[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341699.98
          expect(payment[:due_amount]).to eq 341699.99
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 0.01
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 341699.98
        end
      end

      context 'cashback: 341700.03, exceeded: 0' do
        before do
          contractor.create_gain_cashback_history(341700.03, '20190101', 0)
        end

        # JV画面
        it 'cashbackが次のpaymentにまたがらる こと' do
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 341700.02 # input_ymdがないorderは充当の対象にしなくていい

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0.01
        end

        # Contractor画面
        it 'cashbackが次のpaymentにまたがること' do
          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.98

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 0
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 341700.02
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 0

          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment2[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341699.98
          expect(payment[:due_amount]).to eq 341699.99
          expect(payment[:cashback]).to eq 0.01
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 0
          expect(payment[:remaining_amount]).to eq 341699.98
        end
      end

      context '一部を支払い' do
        before do
          contractor.create_gain_cashback_history(100, '20190101', 0)
          Batch::Daily.exec(to_ymd: '20190215')

          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            payment_ymd: "20190215",
            payment_amount: 200,
            comment: "Any Comment",
            receive_amount_history_count: 0
          }
          post receive_payment_jv_payment_from_contractor_index_path, params: params
        end

        it '支払い済みのcashbackがあること' do
          # JV Payment List
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true
          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 0
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          payment3 = res[:payments].third
          expect(payment3[:exceeded]).to eq 0
          expect(payment3[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 341400.02

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params
          expect(res[:success]).to eq true

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341400.02
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 100
          expect(payment[:exceeded]).to eq 0
          expect(payment[:paid_total_amount]).to eq 200
          expect(payment[:remaining_amount]).to eq 341400.02
        end
      end

      context '一部を支払い' do
        before do
          contractor.update!(pool_amount: 100)
          Batch::Daily.exec(to_ymd: '20190215')

          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            payment_ymd: "20190215",
            payment_amount: 200,
            comment: "Any Comment",
            receive_amount_history_count: 0
          }
          post receive_payment_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          contractor.reload.update!(pool_amount: 400)
        end

        it '支払い済みのexceededがあること' do
          # JV Payment List
          params = {
            auth_token: jv_user.auth_tokens.first.token,
            contractor_id: contractor.id,
            target_ymd: "20190115",
            include_not_due_yet: true
          }
          get payment_list_jv_payment_from_contractor_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:exceeded]).to eq 400
          expect(payment1[:cashback]).to eq 0

          payment2 = res[:payments].second
          expect(payment2[:exceeded]).to eq 0
          expect(payment2[:cashback]).to eq 0

          payment3 = res[:payments].third
          expect(payment3[:exceeded]).to eq 0
          expect(payment3[:cashback]).to eq 0

          # Contractor Payment Status
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            include_paid: "true"
          }
          get payments_contractor_payment_status_index_path, params: params
          expect(res[:success]).to eq true

          payment1 = res[:payments].first
          expect(payment1[:total_amount]).to eq 341000.02

          payment2 = res[:payments].second
          expect(payment2[:total_amount]).to eq 341699.99

          payment3 = res[:payments].third
          expect(payment3[:total_amount]).to eq 341699.99

          # Contractor Payment Detail
          params = {
            auth_token: contractor_user.auth_tokens.first.token,
            payment_id: payment1[:id]
          }
          get payment_detail_contractor_payment_detail_index_path, params: params

          payment = res[:payments]
          expect(payment[:total_amount]).to eq 341000.02
          expect(payment[:due_amount]).to eq 341700.02
          expect(payment[:cashback]).to eq 0
          expect(payment[:exceeded]).to eq 500
          expect(payment[:paid_total_amount]).to eq 200
          expect(payment[:remaining_amount]).to eq 341000.02
        end
      end
    end
  end

  describe 'キャッシュバック' do
    # payment1とpayment2を作成
    # payment1のorder1は返済してキャッシュバックを得る
    # payment1は未完済で、payment2はnext_dueで支払いができる状態
    before do
      jv_user.auth_tokens.create!(token: 'hoge')
      contractor_user.auth_tokens.create!(token: 'fuga')

      # 認証
      params = {
        tax_id: contractor.tax_id,
        username: contractor_user.user_name,
        one_time_passcode: "123456"
      }
      post rudy_verify_account_path, params: params, headers: headers
      @auth_token = res[:auth_token]

      # 注文1
      params = {
        tax_id: contractor.tax_id,
        order_number: "1",
        product_id: product1.product_key,
        dealer_code: cbm_dealer.dealer_code,
        purchase_date: "20190101",
        amount: "1000000.00",
        auth_token: @auth_token
      }
      post rudy_create_order_path, params: params, headers: headers

      # 配送
      params = {
        tax_id: contractor.tax_id,
        order_number: "1",
        dealer_code: cbm_dealer.dealer_code,
        input_date: "20190101"
      }
      post rudy_set_order_input_date_path, params: params, headers: headers


      # 注文2
      params = {
        tax_id: contractor.tax_id,
        order_number: "2",
        product_id: product1.product_key,
        dealer_code: cbm_dealer.dealer_code,
        purchase_date: "20190101",
        amount: "1000000.00",
        auth_token: @auth_token
      }
      post rudy_create_order_path, params: params, headers: headers

      # 配送
      params = {
        tax_id: contractor.tax_id,
        order_number: "2",
        dealer_code: cbm_dealer.dealer_code,
        input_date: "20190101"
      }
      post rudy_set_order_input_date_path, params: params, headers: headers

      Batch::Daily.exec(to_ymd: '20190116')

      # 注文3
      params = {
        tax_id: contractor.tax_id,
        order_number: "3",
        product_id: product1.product_key,
        dealer_code: cbm_dealer.dealer_code,
        purchase_date: "20190116",
        amount: "1000000.00",
        auth_token: @auth_token
      }
      post rudy_create_order_path, params: params, headers: headers

      # 配送
      params = {
        tax_id: contractor.tax_id,
        order_number: "3",
        dealer_code: cbm_dealer.dealer_code,
        input_date: "20190116"
      }
      post rudy_set_order_input_date_path, params: params, headers: headers

      Batch::Daily.exec(to_ymd: '20190201')
    end

    context 'payment' do
      it 'payment1で得たキャッシュバックが、payment1ではなくpayment2に振られること' do
        # payment1 order1 を支払い
        AppropriatePaymentToInstallments.new(contractor, '20190131', 1000000.00, jv_user, 'hoge').call

        expect(contractor.cashback_amount).to_not eq 0

        payment_subtractions = contractor.calc_payment_subtractions

        payment1 = contractor.payments.first
        payment2 = contractor.payments.second
        
        expect(payment_subtractions[payment1.id][:cashback]).to eq 0
        expect(payment_subtractions[payment2.id][:cashback]).to_not eq 0
      end
    end

    context 'over_dueでも値が正しいこと' do
      it 'payment1で得たキャッシュバックが、payment1ではなくpayment2に振られること' do
        # payment1 order1 を支払い
        AppropriatePaymentToInstallments.new(contractor, '20190131', 1000000.00, jv_user, 'hoge').call
        contractor.reload

        # payment1のorder2が遅延
        Batch::Daily.exec(to_ymd: '20190216')
        expect(contractor.payments.first.over_due?).to eq true

        # order1のキャッシュバックは得られている
        expect(contractor.cashback_amount).to_not eq 0

        payment_subtractions = contractor.calc_payment_subtractions

        payment1 = contractor.payments.first
        payment2 = contractor.payments.second

        expect(payment_subtractions[payment1.id][:cashback]).to eq 0
        expect(payment_subtractions[payment2.id][:cashback]).to_not eq 0
      end
    end
  end

  private
  def headers
    bearer_key = JvService::Application.config.try(:rudy_api_auth_key)
    {
      'Authorization': "Bearer #{bearer_key}"
    }
  end
end
