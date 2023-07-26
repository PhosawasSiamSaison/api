require 'rails_helper'

RSpec.describe Rudy::Cpac::CreateSiteInformationController, type: :request do
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
  let(:dealer) { FactoryBot.create(:cpac_dealer)}
  let(:site) { FactoryBot.create(:site, contractor: contractor, site_credit_limit: 1000) }
  let(:eligibility) { FactoryBot.create(:eligibility, contractor: contractor) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20190101')
    FactoryBot.create(:system_setting)
    FactoryBot.create(:rudy_api_setting)

    pdpa_version = FactoryBot.create(:pdpa_version)
    FactoryBot.create(:contractor_user_pdpa_version, contractor_user: contractor_user,
      pdpa_version: pdpa_version)
  end

  describe "POST #call" do
    before do
      FactoryBot.create(:dealer_type_limit, :cpac, eligibility: eligibility)
      FactoryBot.create(:dealer_limit, dealer: dealer, eligibility: eligibility)
    end

    it "オーダーが正しく作成されること" do
      params = {
        tax_id: contractor.tax_id,
        order_type: "service",
        site_code: site.site_code,
        order_number: "1",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        purchase_date: '20190101',
        amount: 990,
        amount_without_tax: 900,
        region: 'sample region',
        bill_date: '',
      }

      post rudy_create_cpac_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      expect(Order.count).to eq 1
      order = Order.first

      expect(order.order_number).to eq '1'
      expect(order.contractor).to eq contractor
      expect(order.dealer).to eq dealer
      expect(order.product.product_key).to eq 1
      expect(order.installment_count).to eq 1
      expect(order.purchase_ymd).to eq '20190101'
      expect(order.purchase_amount).to eq 990
      expect(order.amount_without_tax).to eq 900
      expect(order.paid_up_ymd).to eq nil
      expect(order.input_ymd).to eq '20190101'
      expect(order.input_ymd_updated_at.present?).to eq true
      expect(order.order_user).to eq nil
      expect(order.region).to eq 'sample region'
    end

    it "purchase_ymd, input_ymdには業務日が入ること。引数はrudy_purchase_ymdに入ること" do
      params = {
        tax_id: contractor.tax_id,
        order_type: "service",
        site_code: site.site_code,
        order_number: "1",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        purchase_date: '20181231',
        amount: 990,
        amount_without_tax: 900,
        bill_date: '',
      }

      post rudy_create_cpac_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'OK'

      order = contractor.orders.first
      expect(order.purchase_ymd).to eq '20190101'
      expect(order.input_ymd).to eq '20190101'
      expect(order.rudy_purchase_ymd).to eq '20181231'
    end

    it "購入金額の上限超過でover_site_credit_limitのエラーが返ること" do
      params = {
        tax_id: contractor.tax_id,
        order_type: "service",
        site_code: site.site_code,
        order_number: "1",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        purchase_date: '20190101',
        amount: 2000,
        amount_without_tax: 2000,
        bill_date: '',
      }

      post rudy_create_cpac_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'over_site_credit_limit'
    end

    xdescribe 'over dealer limit' do
      before do
        contractor.latest_dealer_type_limits.first.update!(limit_amount: 3000)
        contractor.latest_dealer_limits.first.update!(limit_amount: 2000)
      end

      it 'available_balanceが返却されること' do
        params = {
          tax_id: contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 2500,
          amount_without_tax: 0,
          region: 'sample region',
          bill_date: '',
        }

        post rudy_create_cpac_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_limit'
        expect(res[:available_balance]).to eq 2000
      end
    end

    xdescribe 'over dealer type limit' do
      let(:contractor) { FactoryBot.create(:contractor) }

      before do
        contractor.latest_dealer_type_limits.first.update!(limit_amount: 3000)
        contractor.latest_dealer_limits.first.update!(limit_amount: 5000)
      end

      it 'available_balanceが返却されること' do
        params = {
          tax_id: contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 4000,
          amount_without_tax: 0,
          region: 'sample region',
          bill_date: '',
        }

        post rudy_create_cpac_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'over_dealer_type_limit'
        expect(res[:available_balance]).to eq 3000
      end
    end

    describe 'over_site_credit_limit' do
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 0,
          amount_without_tax: 0,
          region: 'sample region',
          bill_date: '',
        }
      }

      context '上回る購入金額' do
        it '上限以下のrecreateでover_site_credit_limitエラーにならないこと' do
          params = default_params.dup
          params[:amount] = 1000

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'OK'
        end

        it '上限以上のrecreateでover_site_credit_limitエラーになること' do
          params = default_params.dup
          params[:amount] = 1200

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'over_site_credit_limit'
          expect(res[:site_available_balance]).to eq 1000
        end
      end
    end

    describe 'recreate' do
      let(:order) {
        FactoryBot.create(:order, :inputed_date, contractor: contractor, dealer: dealer, site: site,
          order_number: "1", purchase_amount: 900)
      }
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: order.order_number,
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 990,
          amount_without_tax: 900,
          recreate: true,
          bill_date: '',
        }
      }

      before do
        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', total_amount: 900)
        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215', principal: 900)
      end

      it '存在しないorder_numberの指定でエラーが返ること' do
        params = default_params.dup
        params[:order_number] = "2"

        post rudy_create_cpac_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'order_not_found'
      end

      it '現在のorder, installment, paymentが削除されること' do
        # 変更前の検証
        prev_order = contractor.orders.first
        expect(prev_order.purchase_amount).to eq 900

        installment = prev_order.installments.first
        expect(installment.principal).to eq 900

        payment = prev_order.payments.first
        expect(payment.total_amount).to eq 900

        expect(prev_order.reload.uniq_check_flg).to eq true


        params = default_params.dup
        params[:amount] = 200

        post rudy_create_cpac_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'OK'

        expect(prev_order.reload.uniq_check_flg).to eq nil

        expect(contractor.orders.count).to eq 1
        expect(contractor.payments.count).to eq 1

        order = contractor.orders.first
        expect(order.purchase_amount).to eq 200

        installment = order.installments.first
        expect(installment.principal).to eq 200

        payment = order.payments.first
        expect(payment.total_amount).to eq 200
      end

      describe '支払いずみのinstallmentがある場合' do
        let(:payment) { Payment.find_by(due_ymd: '20190215') }
        let(:order2) {
          FactoryBot.create(:order, contractor: contractor, purchase_amount: 100, site: site,
            order_number: 'R2', dealer: dealer)
        }

        before do
          # 新しいpaymentを作成する為に業務日を変更する
          BusinessDay.update!(business_ymd: '20190215')

          # recreateするオーダーを作成
          FactoryBot.create(:installment, order: order2, payment: payment, due_ymd: '20190215',
            principal: 100)

          # 最初のオーダーは支払い済へ
          order.installments.first.update!(paid_up_ymd: '20190215')

          payment.update!(status: :next_due, total_amount: 1000, paid_total_amount: 900)
        end

        it 'paymentのstatusがpaidになること' do
          params = default_params.dup
          params[:amount] = 100
          params[:order_number] = 'R2'

          post rudy_create_cpac_order_path, params: params, headers: headers
          expect(res[:result]).to eq 'OK'

          expect(payment.reload.status).to eq 'paid'
          expect(Payment.find_by(due_ymd: '20190315').present?).to eq true
        end
      end

      xdescribe 'over dealer limit' do
        before do
          contractor.latest_dealer_type_limits.first.update!(limit_amount: 3000)
          contractor.latest_dealer_limits.first.update!(limit_amount: 2000)
        end

        it 'available_balanceの値が正しいこと' do
          params = default_params.dup
          params[:amount] = 2500

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'over_dealer_limit'
          expect(res[:available_balance]).to eq 2000
        end
      end

      xdescribe 'over dealer type limit' do
        let(:contractor) { FactoryBot.create(:contractor) }

        before do
          contractor.latest_dealer_type_limits.first.update!(limit_amount: 3000)
          contractor.latest_dealer_limits.first.update!(limit_amount: 5000)
        end

        it 'available_balanceが返却されること' do
          params = default_params.dup
          params[:amount] = 4000

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'over_dealer_type_limit'
          expect(res[:available_balance]).to eq 3000
        end
      end

      describe 'over_site_credit_limit' do
        it '同じ購入金額のrecreateでover_site_credit_limitエラーにならないこと' do
          params = default_params.dup

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'OK'
        end

        context '上回る購入金額' do
          it '上限以下のrecreateでover_site_credit_limitエラーにならないこと' do
            params = default_params.dup
            params[:amount] = 1000

            post rudy_create_cpac_order_path, params: params, headers: headers

            expect(res[:result]).to eq 'OK'
          end

          it '上限以上のrecreateでover_site_credit_limitエラーになること' do
            params = default_params.dup
            params[:amount] = 1100

            post rudy_create_cpac_order_path, params: params, headers: headers

            expect(res[:result]).to eq 'NG'
            expect(res[:error]).to eq 'over_site_credit_limit'
            expect(res[:site_available_balance]).to eq 1000
          end
        end
      end
    end

    describe 'SMS' do
      let(:params) {
        {
          tax_id: contractor_user.contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 990,
          amount_without_tax: 900,
          bill_date: '',
        }
      }

      context 'CPAC' do
        before do
          dealer.cpac!
        end

        it "SMSが送信されること" do
          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'OK'

          sms = SmsSpool.first

          expect(sms.present?).to eq true
          expect(sms.message_type).to eq "create_cpac_order"
        end
      end
    end

    it 'region文字数超過エラーになること' do
      params = {
        tax_id: contractor_user.contractor.tax_id,
        order_type: "service",
        site_code: site.site_code,
        order_number: "1",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        purchase_date: '20190101',
        amount: 990,
        amount_without_tax: 900,
        region: 'a' * 51,
        bill_date: '',
      }

      post rudy_create_cpac_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'too_long_region'
    end

    it 'order_type文字数超過エラーになること' do
      params = {
        tax_id: contractor_user.contractor.tax_id,
        order_type: "a" * 31,
        site_code: site.site_code,
        order_number: "1",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        purchase_date: '20190101',
        amount: 990,
        amount_without_tax: 900,
        region: 'a',
        bill_date: '',
      }

      post rudy_create_cpac_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'too_long_order_type'
    end

    it 'bill_date文字数超過エラーになること' do
      params = {
        tax_id: contractor_user.contractor.tax_id,
        order_type: "a" ,
        site_code: site.site_code,
        order_number: "1",
        product_id: 1,
        dealer_code: dealer.dealer_code,
        purchase_date: '20190101',
        amount: 990,
        amount_without_tax: 900,
        region: 'a',
        bill_date: '1' * 16,
      }

      post rudy_create_cpac_order_path, params: params, headers: headers

      expect(res[:result]).to eq 'NG'
      expect(res[:error]).to eq 'too_long_bill_date'
    end

    describe '重複チェック' do
      it "連続送信のチェック" do
        default_params = {
          tax_id: contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 100,
          amount_without_tax: 900,
          region: 'sample region',
          bill_date: '',
        }

        request1 = Thread.new do
          params = default_params.dup
          post rudy_create_cpac_order_path, params: params, headers: headers
        end

        request2 = Thread.new do
          params = default_params.dup
          post rudy_create_cpac_order_path, params: params, headers: headers
        end

        request3 = Thread.new do
          params = default_params.dup
          params[:order_number] = '2'
          post rudy_create_cpac_order_path, params: params, headers: headers
        end

        # # 複数のリクエストを非同期で実行する
        request1.join
        request2.join
        request3.join

        expect(Order.count).to eq 2

        order1 = Order.find_by(order_number: '1')
        order2 = Order.find_by(order_number: '2')

        expect(order1.present?).to eq true
        expect(order2.present?).to eq true
      end

      it "duplicate_orderが返ること" do
        params = {
          tax_id: contractor.tax_id,
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 100,
          amount_without_tax: 900,
          region: 'sample region',
          bill_date: '',
        }

        post rudy_create_cpac_order_path, params: params, headers: headers
        expect(res[:result]).to eq 'OK'

        post rudy_create_cpac_order_path, params: params, headers: headers

        expect(res[:result]).to eq 'NG'
        expect(res[:error]).to eq 'duplicate_order'
      end

      context 'recreate' do
        let(:order) {
          FactoryBot.create(:order, contractor: contractor, dealer: dealer, site: site,
            order_number: "1", purchase_amount: 900)
        }

        it "連続送信のチェック" do
          default_params = {
            tax_id: contractor.tax_id,
            order_type: "service",
            site_code: site.site_code,
            order_number: order.order_number,
            product_id: 1,
            dealer_code: order.dealer.dealer_code,
            purchase_date: '20190101',
            amount: 100,
            amount_without_tax: 900,
            region: 'sample region',
            recreate: true,
            bill_date: '',
          }

          request1 = Thread.new do
            params = default_params.dup
            params[:amount] = 200
            post rudy_create_cpac_order_path, params: default_params, headers: headers
          end

          request2 = Thread.new do
            params = default_params.dup
            params[:amount] = 200
            post rudy_create_cpac_order_path, params: default_params, headers: headers
          end

          # 複数のリクエストを非同期で実行する
          request1.join
          request2.join

          expect(Order.count).to eq 1

          order1 = Order.find_by(order_number: order.order_number)

          expect(order1[:amount]).to_not eq 100
        end
      end

      describe '一意制約のチェック' do
        let(:default_params) {
          {
            tax_id: contractor.tax_id,
            order_type: "service",
            site_code: site.site_code,
            order_number: "1",
            product_id: 1,
            dealer_code: dealer.dealer_code,
            purchase_date: '20190101',
            amount: 100,
            amount_without_tax: 900,
            region: 'sample region',
            bill_date: "",
          }
        }

        it '異なるbill_dateで登録できること' do
          params = default_params.dup

          post rudy_create_cpac_order_path, params: params, headers: headers
          expect(res[:result]).to eq 'OK'

          params[:bill_date] = "uniq_value"

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'OK'
        end

        context '異なるdealer' do
          before do
            dealer = FactoryBot.create(:cpac_dealer, dealer_code: "8931")

            FactoryBot.create(:order, contractor: contractor, dealer: dealer, site: site,
              order_number: default_params[:order_number], purchase_amount: 900)
          end

          it '登録できること' do
            params = default_params.dup
            params[:dealer_code] = dealer.dealer_code

            post rudy_create_cpac_order_path, params: params, headers: headers

            expect(res[:result]).to eq 'OK'
          end
        end

        context '異なるSiteCode' do
          before do
            site = FactoryBot.create(:site, contractor: contractor, site_code: "8931")

            FactoryBot.create(:order, contractor: contractor, dealer: dealer, site: site,
              order_number: default_params[:order_number], purchase_amount: 900)
          end

          it '登録できること' do
            params = default_params.dup
            params[:site_code] = site.site_code

            post rudy_create_cpac_order_path, params: params, headers: headers

            expect(res[:result]).to eq 'OK'
          end
        end
      end
    end

    describe 'パラメーターチェック' do
      describe 'invalid_bill_date' do
        it 'bill_dateの引数なし' do
          params = {
            tax_id: contractor.tax_id,
            order_type: "service",
            site_code: site.site_code,
            order_number: "1",
            product_id: 1,
            dealer_code: dealer.dealer_code,
            purchase_date: '20190101',
            amount: 990,
            amount_without_tax: 900,
            region: 'sample region',
          }

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'invalid_bill_date'
        end

        it 'bill_dateの値がnull' do
          params = {
            tax_id: contractor.tax_id,
            order_type: "service",
            site_code: site.site_code,
            order_number: "1",
            product_id: 1,
            dealer_code: dealer.dealer_code,
            purchase_date: '20190101',
            amount: 990,
            amount_without_tax: 900,
            region: 'sample region',
            bill_date: nil,
          }

          post rudy_create_cpac_order_path, params: params, headers: headers

          expect(res[:result]).to eq 'NG'
          expect(res[:error]).to eq 'invalid_bill_date'
        end
      end
    end

    describe 'Exceeded/Cashbackの自動消し込み' do
      let(:default_params) {
        {
          tax_id: contractor.tax_id,
          input_date: "20220717",
          order_type: "service",
          site_code: site.site_code,
          order_number: "1",
          product_id: 1,
          dealer_code: dealer.dealer_code,
          purchase_date: '20190101',
          amount: 100,
          amount_without_tax: 100,
          region: 'sample region',
          bill_date: '',
        }
      }

      before do
        JvService::Application.config.auto_repayment_exceeded_and_cashback = true

        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :not_due_yet, due_ymd: '20221015', contractor: contractor),
          order: FactoryBot.create(:order, :cpac, :inputed_date, contractor: contractor),
          due_ymd: '20221015', principal: 100,
        )

        contractor.update!(pool_amount: 100)
      end

      it '自動消し込みが実行されていること' do
        post rudy_create_cpac_order_path, params: default_params, headers: headers

        expect(res[:result]).to eq "OK"
        expect(contractor.receive_amount_histories.count).to eq 1
        expect(contractor.receive_amount_histories.first.comment).to eq I18n.t('message.auto_repayment_exceeded_and_cashback_comment')
        expect(MailSpool.receive_payment.count).to eq 1
      end
    end
  end
end
