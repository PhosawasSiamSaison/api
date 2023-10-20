require 'rails_helper'

RSpec.describe Jv::PaymentFromContractorController, type: :controller do
  let(:jv_user) { FactoryBot.create(:jv_user) }
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
        paid_installment3 = Installment.last
        params[:installment_ids] = [paid_installment1.id, paid_installment3.id]

        post :receive_payment, params: params

        paid_installment1.reload
        paid_installment3.reload
        pp res
        expect(res[:success]).to eq true
        expect(paid_installment1.paid_up_ymd).to eq ('20190114')
        expect(paid_installment3.paid_up_ymd).to eq ('20190114')
        # installment.paid_up_ymd = payment_ymd
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
