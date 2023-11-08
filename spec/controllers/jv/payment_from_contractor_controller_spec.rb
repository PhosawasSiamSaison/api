require 'rails_helper'

RSpec.describe Jv::PaymentFromContractorController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:area) { FactoryBot.create(:area) }
  let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }
  let(:auth_token) { FactoryBot.create(:auth_token, tokenable: jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }

  describe '#payment_list' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190116')
    end

    describe 'next_dueのPayment' do
      before do
        order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190102')
        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190131', status: 'next_due')
        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190131')
      end

      it '注文日前の指定日でエラーにならないこと' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          target_ymd: '20181231'
        }

        get :payment_list, params: params
        expect(res[:success]).to eq true
      end
    end

    describe 'not_due_yetのPayment' do
      context 'input_ymdあり' do
        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190116')
          payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', status: 'not_due_yet')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215')
        end

        it '引数なしでも1件取得できること' do
          params = {
            auth_token: auth_token.token,
            contractor_id: contractor.id,
            target_ymd: '20181231'
          }

          get :payment_list, params: params
          expect(res[:payments].count).to eq 1
        end
      end

      context 'input_ymdなし' do
        before do
          order = FactoryBot.create(:order, contractor: contractor, input_ymd: nil)
          payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', status: 'not_due_yet')
          FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215')
        end

        it 'input_ymdがないorderのpaymentが取得できないこと' do
          params = {
            auth_token: auth_token.token,
            contractor_id: contractor.id,
            target_ymd: '20190216',
          }

          get :payment_list, params: params
          expect(res[:success]).to eq true
          payments = res[:payments]
          expect(payments.count).to eq 0
        end
      end
    end

    describe 'no_delay_penalty' do
      before do
        FactoryBot.create(:business_day, business_ymd: '20190216')

        order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
          purchase_amount: 1000.0)
        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'over_due', total_amount: 1000.0)
        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215',
          principal: 1000.0, interest: 0)
      end

      context '遅損金あり' do
        describe '免除あり' do
          it '遅損金の値が正しく返ること' do
            params = {
              auth_token: auth_token.token,
              contractor_id: contractor.id,
              target_ymd: '20190216',
              no_delay_penalty: true,
            }

            # 遅損金があること
            expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0

            get :payment_list, params: params

            expect(res[:success]).to eq true

            payment = res[:payments].first
            installment = payment[:installments].first

            expect(payment[:total_amount]).to eq 1000.0
            expect(installment[:late_charge]).to eq 0
          end

          context 'キャッシュバックあり' do
            it '支払いより少ないcashback' do
              FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 1.0)

              params = {
                auth_token: auth_token.token,
                contractor_id: contractor.id,
                target_ymd: '20190216',
                no_delay_penalty: true,
              }

              # 遅損金があること
              expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0

              get :payment_list, params: params
              expect(res[:success]).to eq true

              payment = res[:payments].first

              expect(payment[:cashback]).to eq 1.0
              expect(payment[:exceeded]).to eq 0.0
            end

            it '支払いより多いcashback' do
              FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 2000.0)

              params = {
                auth_token: auth_token.token,
                contractor_id: contractor.id,
                target_ymd: '20190216',
                no_delay_penalty: true,
              }

              # 遅損金があること
              expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0

              get :payment_list, params: params
              expect(res[:success]).to eq true

              payment = res[:payments].first

              expect(payment[:cashback]).to eq 1000.0
              expect(payment[:exceeded]).to eq 0.0
            end

            context '複数のpayment' do
              before do
                # Orderを追加
                order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
                  purchase_amount: 3000.0)

                payment1 = Payment.first
                payment1.update!(total_amount: 2025.1)
                payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315',
                  status: 'over_due', total_amount: 1025.1)
                payment3 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190415',
                  status: 'next_due', total_amount: 1025.1)

                FactoryBot.create(:installment, order: order, payment: payment1, due_ymd: '20190215',
                  principal: 1000.0, interest: 25.1)
                FactoryBot.create(:installment, order: order, payment: payment2, due_ymd: '20190315',
                  principal: 1000.0, interest: 25.1)
                FactoryBot.create(:installment, order: order, payment: payment3, due_ymd: '20190415',
                  principal: 1000.0, interest: 25.1)

                BusinessDay.update!(business_ymd: '20190316')

                FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 3150.2)
              end

              it 'cashbackの値が正しいこと' do
                params = {
                  auth_token: auth_token.token,
                  contractor_id: contractor.id,
                  target_ymd: '20190316',
                  no_delay_penalty: true,
                }

                get :payment_list, params: params
                expect(res[:success]).to eq true

                payments = res[:payments]
                expect(payments.count).to eq 3
                payment1 = payments.first
                payment2 = payments.second
                payment3 = payments.third

                # 遅損金があること
                late_charge1 = Payment.find(payment1[:id]).calc_total_late_charge('20190316')
                late_charge2 = Payment.find(payment2[:id]).calc_total_late_charge('20190316')
                expect(late_charge2).to be > 0
                expect(late_charge1).to be > late_charge2

                expect(payment1[:cashback]).to eq 2025.1
                expect(payment2[:cashback]).to eq 1025.1
                expect(payment3[:cashback]).to eq 100.0

                expect(payment1[:total_amount]).to eq 2025.1
                installments = payment1[:installments]
                expect(installments.count).to eq 2
                expect(installments.first[:late_charge]).to eq 0
                expect(installments.second[:late_charge]).to eq 0

                expect(payment2[:total_amount]).to eq 1025.1
                installments = payment2[:installments]
                expect(installments.count).to eq 1
                expect(installments.first[:late_charge]).to eq 0
              end
            end
          end
        end

        describe '免除なし' do
          it '遅損金の値が正しく返ること' do
            params = {
              auth_token: auth_token.token,
              contractor_id: contractor.id,
              target_ymd: '20190216',
              no_delay_penalty: false,
            }

            # 遅損金があること
            late_charge = contractor.payments.first.calc_total_late_charge('20190216')
            expect(late_charge).to be > 0

            get :payment_list, params: params
            expect(res[:success]).to eq true

            payment = res[:payments].first
            installment = payment[:installments].first

            expect(payment[:total_amount]).to eq 1000.0 + late_charge
            expect(installment[:late_charge]).to eq late_charge

            expect(contractor.exemption_late_charge_count).to eq 0
          end
        end
        

        context '複数のpayment, installment' do
          before do
            # Orderを追加
            order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
              purchase_amount: 3000.0)

            payment1 = Payment.first
            payment1.update!(total_amount: 2025.1)
            payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315',
              status: 'over_due', total_amount: 1025.1)
            payment3 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190415',
              status: 'next_due', total_amount: 1025.1)

            FactoryBot.create(:installment, order: order, payment: payment1, due_ymd: '20190215',
              principal: 1000.0, interest: 25.1)
            FactoryBot.create(:installment, order: order, payment: payment2, due_ymd: '20190315',
              principal: 1000.0, interest: 25.1)
            FactoryBot.create(:installment, order: order, payment: payment3, due_ymd: '20190415',
              principal: 1000.0, interest: 25.1)

            BusinessDay.update!(business_ymd: '20190316')
          end

          it '免除なし。遅損金の値が正しく返ること' do
            params = {
              auth_token: auth_token.token,
              contractor_id: contractor.id,
              target_ymd: '20190316',
              no_delay_penalty: false,
            }

            get :payment_list, params: params
            expect(res[:success]).to eq true

            payments = res[:payments]
            expect(payments.count).to eq 3
            payment1 = payments.first
            payment2 = payments.second
            payment3 = payments.third

            # 遅損金があること
            late_charge1 = Payment.find(payment1[:id]).calc_total_late_charge('20190316')
            late_charge2 = Payment.find(payment2[:id]).calc_total_late_charge('20190316')
            expect(late_charge2).to be > 0
            expect(late_charge1).to be > late_charge2

            expect(payment1[:total_amount]).to eq (2025.1 + late_charge1).round(2)
            installments = payment1[:installments]
            expect(installments.count).to eq 2
            expect(installments.first[:late_charge]).to be > 0
            expect(installments.second[:late_charge]).to be > 0

            expect(payment2[:total_amount]).to eq (1025.1 + late_charge2).round(2)
            installments = payment2[:installments]
            expect(installments.count).to eq 1
            expect(installments.first[:late_charge]).to be > 0
          end

          it '免除あり。遅損金の値が正しく返ること' do
            params = {
              auth_token: auth_token.token,
              contractor_id: contractor.id,
              target_ymd: '20190316',
              no_delay_penalty: true,
            }

            get :payment_list, params: params
            expect(res[:success]).to eq true

            payments = res[:payments]
            expect(payments.count).to eq 3
            payment1 = payments.first
            payment2 = payments.second
            payment3 = payments.third

            # 遅損金があること
            late_charge1 = Payment.find(payment1[:id]).calc_total_late_charge('20190316')
            late_charge2 = Payment.find(payment2[:id]).calc_total_late_charge('20190316')
            expect(late_charge2).to be > 0
            expect(late_charge1).to be > late_charge2

            expect(payment1[:total_amount]).to eq 2025.1
            installments = payment1[:installments]
            expect(installments.count).to eq 2
            expect(installments.first[:late_charge]).to eq 0
            expect(installments.second[:late_charge]).to eq 0

            expect(payment2[:total_amount]).to eq 1025.1
            installments = payment2[:installments]
            expect(installments.count).to eq 1
            expect(installments.first[:late_charge]).to eq 0
          end
        end
      end

      context '遅損金なし(over_dueだが約定日を指定)' do
        it '免除あり。遅損金の値が正しく返ること' do
          params = {
            auth_token: auth_token.token,
            contractor_id: contractor.id,
            target_ymd: '20190215',
            no_delay_penalty: true,
          }

          # 遅損金がないこと
          expect(contractor.payments.first.calc_total_late_charge('20190215')).to eq 0

          get :payment_list, params: params
          expect(res[:success]).to eq true

          payment = res[:payments].first
          installment = payment[:installments].first

          expect(payment[:total_amount]).to eq 1000.0
          expect(installment[:late_charge]).to eq 0
        end

        it '免除なし。遅損金の値が正しく返ること' do
          params = {
            auth_token: auth_token.token,
            contractor_id: contractor.id,
            target_ymd: '20190215',
            no_delay_penalty: false,
          }

          # 遅損金がないこと
          expect(contractor.payments.first.calc_total_late_charge('20190215')).to eq 0

          get :payment_list, params: params
          expect(res[:success]).to eq true

          payment = res[:payments].first
          installment = payment[:installments].first

          expect(payment[:total_amount]).to eq 1000.0
          expect(installment[:late_charge]).to eq 0
        end
      end
    end

    describe '遅損金が発生し、過去の日付を指定した場合にexceededが正しく算出されること' do
      let(:product1) { Product.find_by(product_key: 1)}
      let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor)}

      before do
        BusinessDay.update!(business_ymd: '20190216')
        contractor.update!(pool_amount: 1016.25)

        order = FactoryBot.create(:order, order_number: '1', contractor: contractor,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          input_ymd: '20190115', purchase_amount: 1000.0, order_user: contractor_user)

        payment = Payment.create!(contractor: contractor, due_ymd: '20190215', total_amount: 1000.0,
          status: 'over_due')

        FactoryBot.create(:installment, order: order, payment: payment,
            installment_number: 1, due_ymd: '20190215', principal: 1000, interest: 0)
      end

      it '遅延する前の日付を指定して、遅延金分のexceededが発生しないこと' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          target_ymd: '20190215'
        }

        get :payment_list, params: params

        expect(res[:success]).to eq true
        payments = res[:payments]
        expect(payments.count).to eq 1
        expect(payments.first[:exceeded]).to eq 1000.0
      end
    end
  end

  describe '#receive_amount_history' do
    it 'returns http success' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        page: 1,
        per_page: 1
      }

      get :receive_amount_history, params: params
      expect(response).to have_http_status(:success)
    end

    describe 'レコードなし' do
      it '0件で取得できること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          page: 1,
          per_page: 3
        }

        get :receive_amount_history, params: params

        expect(res[:success]).to eq true
        expect(res[:receive_amount_histories]).to eq []
        expect(res[:total_count]).to eq 0
      end
    end

    describe 'レコード1件' do
      before do
        FactoryBot.create(:receive_amount_history,
          contractor: contractor, create_user: jv_user)
      end

      it '1件で取得できること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          page: 1,
          per_page: 1
        }

        get :receive_amount_history, params: params

        expect(res[:success]).to eq true
        expect(res[:receive_amount_histories].count).to eq 1
        expect(res[:total_count]).to eq 1

        no_delay_penalty_amount = res[:receive_amount_histories].first
        expect(no_delay_penalty_amount.has_key?(:no_delay_penalty_amount)).to eq true
        expect(no_delay_penalty_amount[:no_delay_penalty_amount].is_a?(Float)).to eq true
      end
    end
  end

  describe '#cancel_order' do
    let(:order) { FactoryBot.create(:order, contractor: contractor)}

    context 'jv_user.staff' do
      before do
        jv_user.staff!
      end

      it 'エラーになること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id
        }

        patch :cancel_order, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end

    context 'input_dateが入力済み' do
      before do
        order.update!(input_ymd: '20190101')
      end

      context 'MD/MGR' do
        before do
          auth_token.tokenable.md!
        end

        it '成功すること' do
          params = {
            auth_token: auth_token.token,
            order_id: order.id
          }

          patch :cancel_order, params: params
          expect(res[:success]).to eq true
        end
      end

      context '' do
        before do
          auth_token.tokenable.md!
        end

        it '成功すること' do
          params = {
            auth_token: auth_token.token,
            order_id: order.id
          }

          patch :cancel_order, params: params
          expect(res[:success]).to eq true
        end
      end
    end

    context 'installmentあり' do
      let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
      let(:product1) { Product.find_by(product_key: 1) }
      let(:order) {
        FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: contractor.main_dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          purchase_amount: 1000000.0, order_user: contractor_user)
      }

      before do
        payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 1000000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000000.0, interest: 0.0)
      end

      it '正常にキャンセルできること' do
        params = {
          auth_token: auth_token.token,
          order_id: order.id
        }

        patch :cancel_order, params: params

        expect(res[:success]).to eq true
        expect(order.reload.canceled_at.present?).to eq true
      end
    end
  end

  describe '#receive_payment' do
    let(:default_params) {
      {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
        payment_ymd: "20190114",
        payment_amount: 100,
        comment: "Test",
        receive_amount_history_count: 0
      }
    }

    before do
      FactoryBot.create(:business_day, business_ymd: '20190114')
    end

    describe 'SMSとMail' do
      before do
        FactoryBot.create(:installment,
          payment: FactoryBot.create(:payment, :next_due, due_ymd: '20190115', contractor: contractor),
          order: FactoryBot.create(:order, :inputed_date, purchase_ymd: '20181213', contractor: contractor),
          due_ymd: '20190115', principal: 100,
        )

        FactoryBot.create(:contractor_user, contractor: contractor, email: 'test@a.com')
      end

      it 'SMSとMailのSpoolが作成されること' do
        post :receive_payment, params: default_params

        expect(SmsSpool.receive_payment.count).to eq 1
        expect(MailSpool.receive_payment.count).to eq 1
      end
    end

    describe 'not_due_yetのPayment' do
      before do
        order = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190114')
        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', status: 'not_due_yet')
        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215')
      end

      it 'SMSとMailのSpoolが作成されること' do
        post :receive_payment, params: default_params

        expect(Payment.count).to eq 1
        expect(Payment.first.paid_total_amount).to eq 100
      end
    end

    describe 'check_payment' do
      before do
        contractor.update!(check_payment: false)
      end

      it 'check_paymentがfalseになること' do
        post :receive_payment, params: default_params

        expect(res[:success]).to eq true
        contractor.reload
        expect(contractor.check_payment).to eq false
      end
    end

    describe '日付のチェック' do
      it '未来日の指定でエラーが返ること' do
        params = default_params.dup
        params[:payment_ymd] = "20190115"

        post :receive_payment, params: params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.invalid_future_date')]
      end
    end

    describe '商品変更の申請チェックバリデーション' do
      before do
        order =
          FactoryBot.create(:order, :inputed_date, :applied_change_product, contractor: contractor)

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor)

        FactoryBot.create(:installment, order: order, payment: payment)
      end

      it '申請がある場合は消し込みエラーになること' do
        post :receive_payment, params: default_params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [
          I18n.t('error_message.has_can_repayment_and_applying_change_product_orders')
        ]
      end
    end

    describe 'RUDY Billing Payment API' do
      let(:order) { FactoryBot.create(:order, contractor: contractor, input_ymd: '20181214') }

      before do
        FactoryBot.create(:rudy_api_setting, user_name: '404')

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor)

        FactoryBot.create(:installment, order: order, payment: payment, principal: 100, interest: 0)
      end

      it 'RUDYがエラーでも消し込みがロールバックしないこと' do
        post :receive_payment, params: default_params

        expect(res[:success]).to eq true

        expect(order.reload.paid_up_ymd).to eq '20190114'
      end
    end

    describe '排他制御チェック' do
      before do
        order = FactoryBot.create(:order, contractor: contractor)

        payment = FactoryBot.create(:payment, :next_due, contractor: contractor)

        FactoryBot.create(:installment, order: order, payment: payment)
        FactoryBot.create(:receive_amount_history, contractor: contractor)
      end

      it '排他エラーが返ること' do
        post :receive_payment, params: default_params
        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.stale_object_error')]
      end
    end

    describe 'select installment_ids for payment' do
      let(:product1) { Product.find_by(product_key: 1)}
      let(:product2) { Product.find_by(product_key: 2) }
      let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190114')
      end
  

      describe 'normal case' do
        before do
          order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190114', purchase_amount: 50)
          payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', status: 'not_due_yet', total_amount: 50)
          FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215', principal: 50)
          order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190214', purchase_amount: 100)
          order3 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190214', purchase_amount: 50)
          payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315', status: 'not_due_yet', total_amount: 150)
          FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190315', principal: 100)
          FactoryBot.create(:installment, order: order3, payment: payment2, due_ymd: '20190315', principal: 50)
        end

        it 'should pay selected installment correctly' do
          params = default_params.dup
          paid_installment1 = Installment.first
          paid_installment2 = Installment.second
          paid_installment3 = Installment.last
          params[:installment_ids] = [paid_installment1.id, paid_installment3.id]

          post :receive_payment, params: params

          paid_installment1.reload
          paid_installment3.reload
          expect(res[:success]).to eq true
          expect(paid_installment1.paid_up_ymd).to eq ('20190114')
          expect(paid_installment2.paid_up_ymd).to eq (nil)
          expect(paid_installment3.paid_up_ymd).to eq ('20190114')
        end
      end

      describe 'with exceed and cashback case' do
        describe 'exceed' do
          before do
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 200.0, status: 'next_due')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
      
            FactoryBot.create(:installment, order: order2, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
            contractor.update!(pool_amount: 150)
          end

          it 'should use exceeded and update pool amount correctly (0 replayment)' do
            params = default_params.dup
            paid_installment1 = Installment.first
            paid_installment3 = Installment.last
            params[:installment_ids] = [paid_installment1.id, paid_installment3.id]
            params[:payment_amount] = 0

            post :receive_payment, params: params
            
            expect(res[:success]).to eq true
            contractor.reload
            paid_installment3.reload

            order1 = Order.find_by(order_number: '1')
            expect(order1.paid_up_ymd).to eq '20190114'
            
            order2 = Order.find_by(order_number: '2')
            expect(order2.paid_up_ymd).to eq nil
            expect(paid_installment3.paid_principal).to eq(50)
    
            # poolが発生していないこと
            expect(contractor.pool_amount).to eq 0
          end
        end

        describe 'use cashback' do
          before do
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)

            order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190201',
              input_ymd: '20190215', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 240.0, status: 'next_due')

            payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
              total_amount: 100.0, status: 'not_due_yet')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
      
            FactoryBot.create(:installment, order: order2, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)

            FactoryBot.create(:installment, order: order3, payment: payment2,
              installment_number: 1, due_ymd: '20190331', principal: 100.0, interest: 0)

            contractor.create_gain_cashback_history(250, '20190101', 0)
          end

          it 'should use cashback and update cashback history correctly (0 replayment)' do
            params = default_params.dup
            paid_installment1 = Installment.first
            paid_installment2 = Installment.second
            paid_installment3 = Installment.last
            params[:installment_ids] = [paid_installment1.id, paid_installment3.id]
            params[:payment_amount] = 0

            post :receive_payment, params: params
            
            expect(res[:success]).to eq true
            contractor.reload
            paid_installment1.reload
            paid_installment2.reload
            paid_installment3.reload

            order1 = Order.find_by(order_number: '1')
            expect(order1.paid_up_ymd).to eq '20190114'
            expect(paid_installment1.paid_principal).to eq(100)
            
            order2 = Order.find_by(order_number: '2')
            expect(order2.paid_up_ymd).to eq nil
            expect(paid_installment2.paid_principal).to eq(50)

            order3 = Order.find_by(order_number: '3')
            expect(order3.paid_up_ymd).to eq "20190114"
            expect(paid_installment3.paid_principal).to eq(100)
    
            # poolが発生していないこと
            expect(contractor.pool_amount).to eq 0

            cashback_use_histories = contractor.cashback_histories.use
            cashback_gain_histories = contractor.cashback_histories.gain
            expect(cashback_use_histories.count).to eq 2
            expect(cashback_gain_histories.count).to eq 3

            # キャッシュバックが正しく使用されていること
            expect(cashback_use_histories.first.cashback_amount).to eq 200
            expect(cashback_use_histories.first.total).to eq 50
    
            # キャッシュバックが正しく使用されていること
            expect(cashback_use_histories.last.cashback_amount).to eq 50
            expect(cashback_use_histories.last.total).to eq 0

            gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190114', point_type: 1, order_id: order1.id)
            expect(gain_cashback_history1).to be_present
            expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)

            expect(gain_cashback_history1.total).to eq(0.46)

            gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190114', point_type: 1, order_id: order2.id)
            expect(gain_cashback_history2).to be_nil

            gain_cashback_history3 = contractor.cashback_histories.find_by(exec_ymd: '20190114', point_type: 1, order_id: order3.id)
            expect(gain_cashback_history3).to be_present
            expect(gain_cashback_history3.cashback_amount).to eq(order2.calc_cashback_amount)

            expect(gain_cashback_history3.total).to eq(0.92)
            expect(gain_cashback_history3.latest).to eq(true)
          end
        end

        describe 'gain cashback' do
          describe 'gain cashback in second due case'
          before do
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190201',
              input_ymd: '20190215', purchase_amount: 100.0, order_user: contractor_user)

            order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190301',
              input_ymd: '20190315', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 240.0, status: 'next_due')

            payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
              total_amount: 100.0, status: 'not_due_yet')

            payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
              total_amount: 100.0, status: 'not_due_yet')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
      
            FactoryBot.create(:installment, order: order2, payment: payment2,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)

            FactoryBot.create(:installment, order: order3, payment: payment3,
              installment_number: 1, due_ymd: '20190331', principal: 100.0, interest: 0)
          end

          it 'should gain cashback and update cashback history correctly when pay at second installment' do
            params = default_params.dup
            paid_installment1 = Installment.first
            paid_installment2 = Installment.second
            paid_installment3 = Installment.last
            params[:installment_ids] = [paid_installment2.id]
            params[:payment_amount] = 100

            post :receive_payment, params: params
            
            expect(res[:success]).to eq true
            contractor.reload
            paid_installment1.reload
            paid_installment2.reload
            paid_installment3.reload

            order2 = Order.find_by(order_number: '2')
            expect(order2.paid_up_ymd).to eq '20190114'
            expect(paid_installment2.paid_principal).to eq(100)

            # poolが発生していないこと
            expect(contractor.pool_amount).to eq 0

            cashback_use_histories = contractor.cashback_histories.use
            cashback_gain_histories = contractor.cashback_histories.gain
            expect(cashback_use_histories.count).to eq 0
            expect(cashback_gain_histories.count).to eq 1

            gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190114', point_type: 1, order_id: order2.id)
            expect(gain_cashback_history1).to be_present
            expect(gain_cashback_history1.cashback_amount).to eq(order2.calc_cashback_amount)

            expect(gain_cashback_history1.total).to eq(order2.calc_cashback_amount)
          end
        end
      end

      describe 'test case' do
        before do
          order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190114', purchase_amount: 2000)
          order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190114', purchase_amount: 2000)

          payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215', status: 'next_due', total_amount: 2683.42)
          payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315',
            status: 'not_due_yet', total_amount: 683.39)
          payment3 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190415',
            status: 'not_due_yet', total_amount: 683.39)

          FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215',
              principal: 2000.0, interest: 0.0)
          FactoryBot.create(:installment, order: order2, payment: payment1, due_ymd: '20190215',
            principal: 666.68, interest: 16.74)
          FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190315',
            principal: 666.66, interest: 16.73)
          FactoryBot.create(:installment, order: order2, payment: payment3, due_ymd: '20190415',
            principal: 666.66, interest: 16.73)
        end

        it 'should pay selected installment partial 2 time success and correctly' do
          # first pay for case 2
          params = default_params.dup
          paid_installment1 = Installment.first
          paid_installment2 = Installment.second
          paid_installment3 = Installment.third
          paid_last_installment = Installment.last

          params[:installment_ids] = [paid_installment1.id, paid_last_installment.id]
          params[:payment_amount] = 2500

          post :receive_payment, params: params

          paid_installment1.reload
          paid_last_installment.reload
          contractor.reload
          expect(res[:success]).to eq true
          expect(paid_installment1.paid_up_ymd).to eq ('20190114')
          expect(paid_installment2.paid_up_ymd).to eq (nil)
          expect(paid_last_installment.paid_up_ymd).to eq (nil)
          expect(contractor.cashback_amount)

          # second pay for case 3
          params = default_params.dup
          params[:installment_ids] = [paid_installment2.id]
          params[:payment_amount] = 500
          params[:receive_amount_history_count] = 1

          post :receive_payment, params: params
          paid_installment1.reload
          paid_installment2.reload
          paid_installment3.reload
          paid_last_installment.reload

          expect(res[:success]).to eq true
          expect(paid_installment1.paid_up_ymd).to eq ('20190114')
          expect(paid_installment2.paid_up_ymd).to eq (nil)
          expect(paid_installment2.paid_principal).to eq (483.26)
          expect(paid_installment2.paid_interest).to eq (16.74)
          # not use cashback because payment not being select and no have any replayment and exceeded left
          expect(paid_installment3.paid_up_ymd).to eq (nil)
          expect(paid_installment3.paid_principal).to eq (0.0)
          expect(paid_installment3.paid_interest).to eq (0.0)
          expect(paid_last_installment.paid_up_ymd).to eq (nil)
          expect(paid_last_installment.paid_principal).to eq (483.27)
          expect(paid_last_installment.paid_interest).to eq (16.73)
        end
      end

      describe 'Receive amount history' do
        describe 'exemption_late_charge' do
          describe '3 order (same payment)' do
            before do
              BusinessDay.update_ymd!('20190216')
      
              order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, input_ymd: '20190115',
                purchase_amount: 1000.0)
              order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, input_ymd: '20190115',
                purchase_amount: 1000.0)
              order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, input_ymd: '20190115',
                purchase_amount: 1000.0)
              payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
                status: 'over_due', total_amount: 3000.0)
              FactoryBot.create(:installment, order: order1, payment: payment, due_ymd: '20190215',
                principal: 1000.0, interest: 0)
              FactoryBot.create(:installment, order: order2, payment: payment, due_ymd: '20190215',
                principal: 1000.0, interest: 0)
              FactoryBot.create(:installment, order: order3, payment: payment, due_ymd: '20190215',
                principal: 1000.0, interest: 0)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment' do
              expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0
              
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              order2 = Order.find_by(order_number: '2')
              installment2 = order2.installments.find_by(installment_number: 1)
              order3 = Order.find_by(order_number: '2')
              installment3 = order3.installments.find_by(installment_number: 1)
              params = default_params.dup
              # exemption only first installment
              all_exemption_late_charge = (installment1.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190216'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (have exemption all as well)' do
              expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0
              
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              order2 = Order.find_by(order_number: '2')
              installment2 = order2.installments.find_by(installment_number: 1)
              order3 = Order.find_by(order_number: '2')
              installment3 = order3.installments.find_by(installment_number: 1)
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge + installment3.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190216'
              params[:no_delay_penalty] = true
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)
            end
          end

          describe '3 order (different payment)' do
            before do
              BusinessDay.update_ymd!('20190516')
      
              order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
                product: product2, installment_count: 3, purchase_ymd: '20190101',
                input_ymd: '20190116', purchase_amount: 1500.0, order_user: contractor_user)
    
              payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
                total_amount: 512.55, status: 'over_due')
              payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
                total_amount: 512.55, status: 'over_due')
              payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
                total_amount: 512.55, status: 'over_due')
    
              FactoryBot.create(:installment, order: order, payment: payment1,
                installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 12.55)
              FactoryBot.create(:installment, order: order, payment: payment2,
                installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
              FactoryBot.create(:installment, order: order, payment: payment3,
                installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay all installment)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              params = default_params.dup
              # exemption only select installment
              all_exemption_late_charge = (installment1.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190516'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay all installment and have exemption all)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge + installment3.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190516'
              params[:no_delay_penalty] = true
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay 2 installment)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id, installment2.id]
              params[:payment_amount] = 1025.1
              params[:payment_ymd] = '20190516'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay 2 installment partial)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id, installment2.id]
              params[:payment_amount] = 1000
              params[:payment_ymd] = '20190516'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)
            end
          end
        end
      end

      describe 'ReceiveAmountDetail' do
        describe 'exceeded' do
          before do
            BusinessDay.update_ymd!('20190228')
            FactoryBot.create(:business_day, business_ymd: '20190228')
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 240.0, status: 'next_due')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 20)
      
            FactoryBot.create(:installment, order: order2, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 20)
          end

          it 'should create a exceeded ReceiveAmountDetail correctly if select only 1 installment' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            order2 = Order.find_by(order_number: '2')
            installment2 = order2.installments.find_by(installment_number: 1)
            params = default_params.dup

            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 340
            params[:payment_ymd] = '20190228'
  
            post :receive_payment, params: params

            contractor.reload
  
            expect(contractor.pool_amount).to eq 100
    
            order1.reload
            expect(order1.paid_up_ymd).to eq '20190228'

            order2.reload
            expect(order2.paid_up_ymd).to eq '20190228'
  
            expect(ReceiveAmountDetail.count).to eq 2
  
            receive_amount_detail1 = ReceiveAmountDetail.first
            receive_amount_detail2 = ReceiveAmountDetail.last
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
            expect(receive_amount_detail1.exceeded_occurred_amount).to eq(0)
            expect(receive_amount_detail1.exceeded_occurred_ymd).to eq(nil)
            expect(receive_amount_detail1.paid_principal).to eq(100)
            expect(receive_amount_detail1.paid_interest).to eq(20)

            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
            expect(receive_amount_detail2.exceeded_occurred_amount).to eq(100)
            expect(receive_amount_detail2.exceeded_occurred_ymd).to eq('20190228')
            expect(receive_amount_detail2.paid_principal).to eq(100)
            expect(receive_amount_detail2.paid_interest).to eq(20)

            # Gain cashback
            expect(receive_amount_detail1.cashback_occurred_amount).to eq(order1.calc_cashback_amount)
            expect(receive_amount_detail1.cashback_paid_amount).to eq(0.0)
            expect(receive_amount_detail2.cashback_occurred_amount).to eq(order2.calc_cashback_amount)
            expect(receive_amount_detail1.cashback_paid_amount).to eq(0.0)
    
          end
      
          it 'should not create a exceeded ReceiveAmountDetail record if there have exceeded value stamp on selected paid order' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            order2 = Order.find_by(order_number: '2')
            installment2 = order2.installments.find_by(installment_number: 1)
            params = default_params.dup

            params[:installment_ids] = [installment1.id, installment2.id]
            params[:payment_amount] = 340
            params[:payment_ymd] = '20190228'
  
            post :receive_payment, params: params

            expect(res[:success]).to eq true
            contractor.reload
  
            expect(contractor.pool_amount).to eq 100
    
            order1.reload
            expect(order1.paid_up_ymd).to eq '20190228'

            order2.reload
            expect(order2.paid_up_ymd).to eq '20190228'
  
            expect(ReceiveAmountDetail.count).to eq 2
  
            receive_amount_detail1 = ReceiveAmountDetail.first
            receive_amount_detail2 = ReceiveAmountDetail.last
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
            expect(receive_amount_detail1.exceeded_occurred_amount).to eq(0)
            expect(receive_amount_detail1.exceeded_occurred_ymd).to eq(nil)
            expect(receive_amount_detail1.paid_principal).to eq(100)
            expect(receive_amount_detail1.paid_interest).to eq(20)

            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
            expect(receive_amount_detail2.exceeded_occurred_amount).to eq(100)
            expect(receive_amount_detail2.exceeded_occurred_ymd).to eq('20190228')
            expect(receive_amount_detail2.paid_principal).to eq(100)
            expect(receive_amount_detail2.paid_interest).to eq(20)

            # Gain cashback
            expect(receive_amount_detail1.cashback_occurred_amount).to eq(order1.calc_cashback_amount)
            expect(receive_amount_detail1.cashback_paid_amount).to eq(0.0)
            expect(receive_amount_detail2.cashback_occurred_amount).to eq(order2.calc_cashback_amount)
            expect(receive_amount_detail2.cashback_paid_amount).to eq(0.0)
          end
        end

        describe 'replayment the paid installment' do
          before do
            BusinessDay.update_ymd!('20190228')
            FactoryBot.create(:business_day, business_ymd: '20190228')
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 240.0, status: 'next_due')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 20)
      
            FactoryBot.create(:installment, order: order2, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 20)
          end

          it 'should not create a exceeded ReceiveAmountDetail correctly if select paid installment but still can fifo replayment' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            order2 = Order.find_by(order_number: '2')
            installment2 = order2.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 120
            params[:payment_ymd] = '20190228'

            post :receive_payment, params: params

            expect(res[:success]).to eq true
            contractor.reload
  
            expect(contractor.pool_amount).to eq 0
    
            order1.reload
            expect(order1.paid_up_ymd).to eq '20190228'
  
            receive_amount_detail1 = ReceiveAmountDetail.first
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
            expect(receive_amount_detail1.exceeded_occurred_amount).to eq(0)
            expect(receive_amount_detail1.exceeded_occurred_ymd).to eq(nil)
            expect(receive_amount_detail1.paid_principal).to eq(100)
            expect(receive_amount_detail1.paid_interest).to eq(20)

            # Gain cashback
            expect(receive_amount_detail1.cashback_occurred_amount).to eq(order1.calc_cashback_amount)
            expect(receive_amount_detail1.cashback_paid_amount).to eq(0.0)

            params[:receive_amount_history_count] = 1
            # paid same parameter (select paid payment)
            post :receive_payment, params: params


            expect(res[:success]).to eq true
            order2.reload
            expect(order2.paid_up_ymd).to eq '20190228'

            contractor.reload
  
            expect(contractor.pool_amount).to eq 0
  
            expect(ReceiveAmountDetail.count).to eq 2

            receive_amount_detail2 = ReceiveAmountDetail.last
            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
            expect(receive_amount_detail2.exceeded_occurred_amount).to eq(0)
            expect(receive_amount_detail2.exceeded_occurred_ymd).to eq(nil)
            expect(receive_amount_detail2.paid_principal).to eq(100)
            expect(receive_amount_detail2.paid_interest).to eq(20)
             # Gain cashback
            expect(receive_amount_detail2.cashback_occurred_amount).to eq(order2.calc_cashback_amount)
            expect(receive_amount_detail2.cashback_paid_amount).to eq(0.0)
    
          end
        end

        describe 'exemption_late_charge' do
          describe '3 order (same payment)' do
            before do
              BusinessDay.update_ymd!('20190216')
      
              order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, input_ymd: '20190115',
                purchase_amount: 1000.0)
              order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, input_ymd: '20190115',
                purchase_amount: 1000.0)
              order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, input_ymd: '20190115',
                purchase_amount: 1000.0)
              payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
                status: 'over_due', total_amount: 3000.0)
              FactoryBot.create(:installment, order: order1, payment: payment, due_ymd: '20190215',
                principal: 1000.0, interest: 0)
              FactoryBot.create(:installment, order: order2, payment: payment, due_ymd: '20190215',
                principal: 1000.0, interest: 0)
              FactoryBot.create(:installment, order: order3, payment: payment, due_ymd: '20190215',
                principal: 1000.0, interest: 0)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment' do
              expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0
              
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              order2 = Order.find_by(order_number: '2')
              installment2 = order2.installments.find_by(installment_number: 1)
              order3 = Order.find_by(order_number: '3')
              installment3 = order3.installments.find_by(installment_number: 1)
              params = default_params.dup
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              all_exemption_late_charge = (installment1.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190216'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # all 3 order are in same payment so all of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 3
  
              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              receive_amount_detail3 = ReceiveAmountDetail.last
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(0)
              expect(receive_amount_detail3.waive_late_charge).to eq(0)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (have no_delay_penalty true)' do
              expect(contractor.payments.first.calc_total_late_charge('20190216')).to be > 0
              
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              order2 = Order.find_by(order_number: '2')
              installment2 = order2.installments.find_by(installment_number: 1)
              order3 = Order.find_by(order_number: '3')
              installment3 = order3.installments.find_by(installment_number: 1)
              params = default_params.dup
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge + installment3.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190216'
              # no_delay_penalty
              params[:no_delay_penalty] = true
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # all 3 order are in same payment so all of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 3
  
              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              receive_amount_detail3 = ReceiveAmountDetail.last
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(installment2_calc_late_charge)
              expect(receive_amount_detail3.waive_late_charge).to eq(installment3_calc_late_charge)
            end
          end

          describe '3 order (different payment)' do
            before do
              BusinessDay.update_ymd!('20190516')
      
              order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
                product: product2, installment_count: 3, purchase_ymd: '20190101',
                input_ymd: '20190116', purchase_amount: 1500.0, order_user: contractor_user)
    
              payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
                total_amount: 512.55, status: 'over_due')
              payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
                total_amount: 512.55, status: 'over_due')
              payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
                total_amount: 512.55, status: 'over_due')
    
              FactoryBot.create(:installment, order: order, payment: payment1,
                installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 12.55)
              FactoryBot.create(:installment, order: order, payment: payment2,
                installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
              FactoryBot.create(:installment, order: order, payment: payment3,
                installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay all installment)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190516'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # all 3 installment are being paid so all of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 3
  
              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              receive_amount_detail3 = ReceiveAmountDetail.last
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(0)
              expect(receive_amount_detail3.waive_late_charge).to eq(0)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay all installment and have no_delay_penalty true)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge + installment3.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 2000
              params[:payment_ymd] = '20190516'
              params[:no_delay_penalty] = true
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # all 3 installment are being paid so all of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 3
  
              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              receive_amount_detail3 = ReceiveAmountDetail.last
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(installment2_calc_late_charge)
              expect(receive_amount_detail3.waive_late_charge).to eq(installment3_calc_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay 2 installment)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id, installment2.id]
              params[:payment_amount] = 1025.1
              params[:payment_ymd] = '20190516'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # only 2 installment are being paid so only 2 of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 2

              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(installment2_calc_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay 2 installment and have no_delay_penalty true)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 1025.1
              params[:payment_ymd] = '20190516'
              params[:no_delay_penalty] = true
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # only 2 installment are being paid so only 2 of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 2

              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(installment2_calc_late_charge)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay 2 installment partial)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 1000
              params[:payment_ymd] = '20190516'
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # only 2 installment are being paid so only 2 of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 2

              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(0)
            end

            it 'should save and update exemption_late_charge correctly when selected installment and go to fifo payment (pay 2 installment partial and have no_delay_penalty true)' do
              order1 = Order.find_by(order_number: '1')
              installment1 = order1.installments.find_by(installment_number: 1)
              installment2 = order1.installments.find_by(installment_number: 2)
              installment3 = order1.installments.find_by(installment_number: 3)
              expect(installment1.calc_late_charge).to be > 0
              expect(installment2.calc_late_charge).to be > 0
              expect(installment3.calc_late_charge).to be > 0
              installment1_calc_late_charge = installment1.calc_late_charge
              installment2_calc_late_charge = installment2.calc_late_charge
              installment3_calc_late_charge = installment3.calc_late_charge
              params = default_params.dup
              all_exemption_late_charge = (installment1.calc_late_charge + installment2.calc_late_charge).round(2)

              # make first installment paid
              params[:installment_ids] = [installment1.id]
              params[:payment_amount] = 1000
              params[:payment_ymd] = '20190516'
              params[:no_delay_penalty] = true
              params[:no_selected_delay_penalty] = true

              post :receive_payment, params: params

              expect(res[:success]).to eq true

              contractor.reload
              expect(contractor.exemption_late_charge_count).to eq 1

              receive_amount_history = ReceiveAmountHistory.first
              expect(receive_amount_history.exemption_late_charge).to eq(all_exemption_late_charge)

              # only 2 installment are being paid so only 2 of them will be exemption_late_charge and create ReceiveAmountDetail 
              expect(ReceiveAmountDetail.count).to eq 2

              receive_amount_detail1 = ReceiveAmountDetail.first
              receive_amount_detail2 = ReceiveAmountDetail.second
              expect(receive_amount_detail1.waive_late_charge).to eq(installment1_calc_late_charge)

              expect(receive_amount_detail2.waive_late_charge).to eq(installment2_calc_late_charge)
            end
          end
        end
      end

      describe 'no_delay_penalty' do
        describe '1 order' do
          before do
            BusinessDay.update_ymd!('20190216')
    
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, input_ymd: '20190115',
              purchase_amount: 1000.0)
            payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
              status: 'over_due', total_amount: 1000.0)
            FactoryBot.create(:installment, order: order1, payment: payment, due_ymd: '20190215',
              principal: 1000.0, interest: 0)
          end

          it 'should not add exemption_late_charge_count when no_delay_penalty is false' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 1000
            params[:payment_ymd] = '20190216'
            params[:no_delay_penalty] = false

            post :receive_payment, params: params

            expect(res[:success]).to eq true

            contractor.reload
            expect(contractor.exemption_late_charge_count).to eq 0
          end
  
          it 'should add exemption_late_charge_count correctly' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 1000
            params[:payment_ymd] = '20190216'
            params[:no_selected_delay_penalty] = true

            post :receive_payment, params: params

            expect(res[:success]).to eq true

            contractor.reload
            expect(contractor.exemption_late_charge_count).to eq 1
          end

          it 'should add exemption_late_charge_count correctly (no have remain installment that can pay left)' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 1000
            params[:payment_ymd] = '20190216'
            params[:no_selected_delay_penalty] = true

            post :receive_payment, params: params

            expect(res[:success]).to eq true

            contractor.reload
            expect(contractor.exemption_late_charge_count).to eq 1
          end

          it 'should add exemption_late_charge_count correctly (parital pay)' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 500
            params[:payment_ymd] = '20190216'
            params[:no_selected_delay_penalty] = true

            post :receive_payment, params: params

            expect(res[:success]).to eq true

            contractor.reload
            expect(contractor.exemption_late_charge_count).to eq 1
          end
        end

        describe '3 order (same payment)' do
          before do
            BusinessDay.update_ymd!('20190216')
    
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, input_ymd: '20190115',
              purchase_amount: 1000.0)
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, input_ymd: '20190115',
              purchase_amount: 1000.0)
            order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, input_ymd: '20190115',
              purchase_amount: 1000.0)
            payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
              status: 'over_due', total_amount: 3000.0)
            FactoryBot.create(:installment, order: order1, payment: payment, due_ymd: '20190215',
              principal: 1000.0, interest: 0)
            FactoryBot.create(:installment, order: order2, payment: payment, due_ymd: '20190215',
              principal: 1000.0, interest: 0)
            FactoryBot.create(:installment, order: order3, payment: payment, due_ymd: '20190215',
              principal: 1000.0, interest: 0)
          end

          it 'should not add exemption_late_charge_count when no_delay_penalty is false' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 2000
            params[:payment_ymd] = '20190216'
            params[:no_delay_penalty] = false

            post :receive_payment, params: params

            expect(res[:success]).to eq true

            contractor.reload
            expect(contractor.exemption_late_charge_count).to eq 0
          end
  
          it 'should add exemption_late_charge_count correctly (have remain installment that can pay left)' do
            order1 = Order.find_by(order_number: '1')
            installment1 = order1.installments.find_by(installment_number: 1)
            params = default_params.dup

            # make first installment paid
            params[:installment_ids] = [installment1.id]
            params[:payment_amount] = 2000
            params[:payment_ymd] = '20190216'
            params[:no_selected_delay_penalty] = true

            post :receive_payment, params: params

            expect(res[:success]).to eq true

            contractor.reload
            expect(contractor.exemption_late_charge_count).to eq 1
          end
        end
      end
    end
  end

  describe '#contractor_status' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20190114')
      contractor.update!(exemption_late_charge_count: 1)
    end

    it '値が正常に取得できること' do
      params = {
        auth_token: auth_token.token,
        contractor_id: contractor.id,
      }

      post :contractor_status, params: params
      expect(res[:success]).to eq true

      expect(res[:contractor_status].has_key?(:exempt_delay_penalty_count)).to eq true
      expect(res[:contractor_status][:exempt_delay_penalty_count]).to eq 1
      expect(res[:contractor_status][:delay_penalty_count]).to eq 0
    end
  end

  describe '#update_history_comment' do
    before do
      FactoryBot.create(:receive_amount_history, contractor: contractor, comment: 'a')
    end

    context 'MD/MGR' do
      before do
        jv_user.md?
      end

      it '成功すること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          receive_amount_history: {
            id: contractor.receive_amount_histories.first.id,
            comment: "b"
          }
        }

        patch :update_history_comment, params: params

        expect(res[:success]).to eq true
        expect(contractor.receive_amount_histories.first.comment).to eq "b"
      end
    end

    context 'staff' do
      before do
        jv_user.staff!
      end

      it '権限エラーが返ること' do
        params = {
          auth_token: auth_token.token,
          contractor_id: contractor.id,
          receive_amount_history: {
            id: contractor.receive_amount_histories.first.id,
            comment: "b"
          }
        }

        patch :update_history_comment, params: params

        expect(res[:success]).to eq false
        expect(res[:errors]).to eq [I18n.t('error_message.permission_denied')]
      end
    end
  end
end
