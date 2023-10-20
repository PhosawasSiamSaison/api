# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppropriatePaymentToSelectedInstallments, type: :model do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:area) { FactoryBot.create(:area) }
  let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }
  let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
  let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:product3) { Product.find_by(product_key: 3) }
  let(:product4) { Product.find_by(product_key: 4) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20190228')
  end

  describe 'No late loss' do
    describe '1 order' do
      describe 'One-time payment' do
        before do
          order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 500.0, order_user: contractor_user)

          payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 500.0, status: 'next_due')

          FactoryBot.create(:installment, order: order1, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 500.0, interest: 0.0)

          order2 = FactoryBot.create(
            :order,
            contractor: contractor,
            input_ymd: '20190214',
            purchase_amount: 100,
            dealer: dealer,
            product: product1,
            installment_count: 1,
            purchase_ymd: '20190101',
            order_user: contractor_user
          )
          order3 = FactoryBot.create(
            :order,
            contractor: contractor,
            input_ymd: '20190214',
            purchase_amount: 50,
            dealer: dealer,
            product: product1,
            installment_count: 1,
            purchase_ymd: '20190101',
            order_user: contractor_user
          )
          payment2 = FactoryBot.create(
            :payment,
            contractor: contractor,
            due_ymd: '20190315',
            status: 'not_due_yet',
            total_amount: 150
          )
          FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190315', principal: 100)
          FactoryBot.create(:installment, order: order3, payment: payment2, due_ymd: '20190315', principal: 50)
        end

        describe 'Payment on contract date (20190228)' do
          it 'pay in full' do
            paid_installment1 = Installment.first
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              500.0,
              jv_user,
              'hoge',
              installment_ids: [paid_installment1.id]
            ).call
            paid_installment1.reload

            expect(result[:remaining_input_amount]).to eq(0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq '20190228'

            # Payment
            payment = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment.total_amount).to eq 500.0
            expect(payment.paid_total_amount).to eq 500.0
            expect(payment.paid_up_ymd).to eq '20190228'
            expect(payment.paid_up_operated_ymd).to eq '20190228'
            expect(payment.status).to eq 'paid'

            # Installment1
            expect(paid_installment1.due_ymd).to eq '20190228'
            expect(paid_installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(paid_installment1.principal).to eq 500.0
            expect(paid_installment1.interest).to eq 0.0
            # 支払い済み
            expect(paid_installment1.paid_principal).to eq 500.0
            expect(paid_installment1.paid_interest).to eq 0.0
            expect(paid_installment1.paid_late_charge).to eq 0.0

            # Receive Amount History の検証
            expect(contractor.receive_amount_histories.count).to eq 1
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 500.0
            receive_amount_detail = ReceiveAmountDetail.find_by(installment_id: paid_installment1.id)
            expect(receive_amount_detail).to be_present
            expect(receive_amount_detail.repayment_ymd).to eq('20190228')
            expect(contractor.cashback_amount).to eq(2.33)
          end

          it 'Partial payment (450)' do
            paid_installment1 = Installment.first
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              450.0,
              jv_user,
              'hoge',
              installment_ids: [paid_installment1.id]
            ).call

            paid_installment1.reload

            expect(result[:remaining_input_amount]).to eq(0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment
            payment = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment.total_amount.to_f).to eq 500.0
            expect(payment.paid_total_amount.to_f).to eq 450.0
            expect(payment.paid_up_ymd).to eq nil
            expect(payment.paid_up_operated_ymd).to eq nil
            expect(payment.status).to eq 'next_due'

            # Installment1
            expect(paid_installment1.due_ymd).to eq '20190228'
            expect(paid_installment1.paid_up_ymd).to eq nil
            # 支払い予定
            expect(paid_installment1.principal.to_f).to eq 500.0
            expect(paid_installment1.interest.to_f).to eq 0.0
            # 支払い済み
            expect(paid_installment1.paid_principal.to_f).to eq 450.0
            expect(paid_installment1.paid_interest.to_f).to eq 0.0
            expect(paid_installment1.paid_late_charge.to_f).to eq 0.0

            expect(contractor.receive_amount_histories.count).to eq 1
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 450.0

            receive_amount_detail = ReceiveAmountDetail.find_by(installment_id: paid_installment1.id)
            expect(receive_amount_detail).to be_present
            expect(receive_amount_detail.repayment_ymd).to eq('20190228')
          end

          it 'Pay surplus (600) and return remaining_input_amount correctly (not add to pool_amount)' do
            paid_installment1 = Installment.first
            result = AppropriatePaymentToSelectedInstallments.new(contractor,
              '20190228',
              600.0,
              jv_user,
              'hoge',
              installment_ids: [paid_installment1.id]
            ).call
            contractor.reload
            paid_installment1.reload

            expect(result[:remaining_input_amount]).to eq(100.0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay exceed so must have this to other loop
            # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
            # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
            #   item[:installment_id] == paid_installment1.id
            # end
            # expect(receive_amount_detail_data1[:installment_id]).to eq(paid_installment1.id)
            # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.0)

            # Payment
            payment = contractor.payments.first
            expect(payment.due_ymd).to eq '20190228'
            expect(payment.total_amount).to eq 500.0
            expect(payment.paid_total_amount).to eq 500.0
            expect(payment.status).to eq 'paid'

            # Installment1
            expect(paid_installment1.due_ymd).to eq '20190228'
            expect(paid_installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(paid_installment1.principal).to eq 500.0
            expect(paid_installment1.interest).to eq 0.0
            # 支払い済み
            expect(paid_installment1.paid_principal).to eq 500.0
            expect(paid_installment1.paid_interest).to eq 0.0
            expect(paid_installment1.paid_late_charge).to eq 0.0

            expect(contractor.receive_amount_histories.count).to eq 1
            expect(contractor.receive_amount_histories.first.id).to eq result[:receive_amount_history_id]

            expect(contractor.pool_amount).to eq 0.0
          end
        end
      end

      describe '3 payments' do
        before do
          order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product2, installment_count: 3, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 1500.0, order_user: contractor_user)

          payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 512.55, status: 'next_due')
          payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
            total_amount: 512.55, status: 'not_due_yet')
          payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
            total_amount: 512.55, status: 'not_due_yet')

          FactoryBot.create(:installment, order: order, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 12.55)
          FactoryBot.create(:installment, order: order, payment: payment2,
            installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
          FactoryBot.create(:installment, order: order, payment: payment3,
            installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
        end

        describe 'Payment on contract date (20190228)' do
          it 'Pay in full for the first time (paid all installment)' do
            installment1 = contractor.installments.find_by(installment_number: 1)
            installment2 = contractor.installments.find_by(installment_number: 2)
            installment3 = contractor.installments.find_by(installment_number: 3)
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              1537.65,
              jv_user,
              'hoge',
              installment_ids: [installment1.id, installment2.id, installment3.id]
            ).call

            expect(result[:remaining_input_amount]).to eq(0.0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq '20190228'

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 512.55
            expect(payment1.paid_total_amount.to_f).to eq 512.55
            expect(payment1.status).to eq 'paid'

            # Installment 1
            installment1.reload
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment1.principal).to eq 500
            expect(installment1.interest).to eq 12.55
            # 支払い済み
            expect(installment1.paid_principal).to eq 500
            expect(installment1.paid_interest).to eq 12.55
            expect(installment1.paid_late_charge).to eq 0.0


            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 512.55
            expect(payment2.paid_total_amount.to_f).to eq 512.55

            # Installment 2
            installment2.reload
            expect(installment2.due_ymd).to eq '20190331'
            expect(installment2.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment2.principal).to eq 500
            expect(installment2.interest).to eq 12.55
            # 支払い済み
            expect(installment2.paid_principal).to eq 500
            expect(installment2.paid_interest).to eq 12.55
            expect(installment2.paid_late_charge).to eq 0.0

            payment3 = contractor.payments.find_by(due_ymd: '20190430')
            expect(payment3.total_amount.to_f).to eq 512.55
            expect(payment3.paid_total_amount.to_f).to eq 512.55

            # Installment 2
            installment3.reload
            expect(installment3.due_ymd).to eq '20190430'
            expect(installment3.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment3.principal).to eq 500
            expect(installment3.interest).to eq 12.55
            # 支払い済み
            expect(installment3.paid_principal).to eq 500
            expect(installment3.paid_interest).to eq 12.55
            expect(installment3.paid_late_charge).to eq 0.0

            expect(contractor.receive_amount_histories.count).to eq 1
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 1537.65
            receive_amount_detail1 = ReceiveAmountDetail.find_by(installment_id: installment1.id)
            expect(receive_amount_detail1).to be_present
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
            receive_amount_detail2 = ReceiveAmountDetail.find_by(installment_id: installment2.id)
            expect(receive_amount_detail2).to be_present
            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
            receive_amount_detail2 = ReceiveAmountDetail.find_by(installment_id: installment3.id)
            expect(receive_amount_detail2).to be_present
            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
          end

          it 'pay first and last installment' do
            installment1 = contractor.installments.find_by(installment_number: 1)
            installment2 = contractor.installments.find_by(installment_number: 2)
            installment3 = contractor.installments.find_by(installment_number: 3)
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              1025.10,
              jv_user,
              'hoge',
              installment_ids: [installment1.id, installment3.id]
            ).call

            expect(result[:remaining_input_amount]).to eq(0.0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 512.55
            expect(payment1.paid_total_amount.to_f).to eq 512.55
            expect(payment1.status).to eq 'paid'

            # Installment 1
            installment1.reload
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment1.principal).to eq 500
            expect(installment1.interest).to eq 12.55
            # 支払い済み
            expect(installment1.paid_principal).to eq 500
            expect(installment1.paid_interest).to eq 12.55
            expect(installment1.paid_late_charge).to eq 0.0

            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 512.55
            expect(payment2.paid_total_amount.to_f).to eq 0.0

            # Installment 2
            installment2.reload
            expect(installment2.due_ymd).to eq '20190331'
            expect(installment2.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment2.principal).to eq 500
            expect(installment2.interest).to eq 12.55
            # 支払い済み
            expect(installment2.paid_principal).to eq 0.0
            expect(installment2.paid_interest).to eq 0.0
            expect(installment2.paid_late_charge).to eq 0.0

            payment3 = contractor.payments.find_by(due_ymd: '20190430')
            expect(payment3.total_amount.to_f).to eq 512.55
            expect(payment3.paid_total_amount.to_f).to eq 512.55

            # Installment 2
            installment3.reload
            expect(installment3.due_ymd).to eq '20190430'
            expect(installment3.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment3.principal).to eq 500
            expect(installment3.interest).to eq 12.55
            # 支払い済み
            expect(installment3.paid_principal).to eq 500
            expect(installment3.paid_interest).to eq 12.55
            expect(installment3.paid_late_charge).to eq 0.0

            expect(contractor.receive_amount_histories.count).to eq 1
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 1025.10
            receive_amount_detail1 = ReceiveAmountDetail.find_by(installment_id: installment1.id)
            expect(receive_amount_detail1).to be_present
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
            receive_amount_detail2 = ReceiveAmountDetail.find_by(installment_id: installment3.id)
            expect(receive_amount_detail2).to be_present
            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
          end

          it 'Interest only payment for the first time' do
            installment1 = contractor.installments.find_by(installment_number: 1)
            result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 12.55, jv_user, 'hoge',installment_ids: [installment1.id]).call

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 512.55
            expect(payment1.paid_total_amount.to_f).to eq 12.55
            expect(payment1.status).to eq 'next_due'

            # Installment 1
            installment1 = contractor.installments.find_by(installment_number: 1)
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment1.principal).to eq 500.00
            expect(installment1.interest).to eq 12.55
            # 支払い済み
            expect(installment1.paid_principal).to eq 0.0
            expect(installment1.paid_interest).to eq 12.55
            expect(installment1.paid_late_charge).to eq 0.0
            expect(contractor.receive_amount_histories.count).to eq 1
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 12.55
            receive_amount_detail1 = ReceiveAmountDetail.find_by(installment_id: installment1.id)
            expect(receive_amount_detail1).to be_present
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
          end

          it 'select all installment but pay only 100.0' do
            installment1 = contractor.installments.find_by(installment_number: 1)
            installment2 = contractor.installments.find_by(installment_number: 2)
            installment3 = contractor.installments.find_by(installment_number: 3)
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              100.0,
              jv_user,
              'hoge',
              installment_ids: [installment1.id, installment2.id, installment3.id]
            ).call

            expect(result[:remaining_input_amount]).to eq(0.0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 512.55
            expect(payment1.paid_total_amount.to_f).to eq 100.00

            # Installment 1
            installment1.reload
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment1.principal).to eq 500
            expect(installment1.interest).to eq 12.55
            # 支払い済み
            expect(installment1.paid_principal).to eq 87.45
            expect(installment1.paid_interest).to eq 12.55
            expect(installment1.paid_late_charge).to eq 0.0

            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 512.55
            expect(payment2.paid_total_amount.to_f).to eq 0.0

            # Installment 2
            installment2.reload
            expect(installment2.due_ymd).to eq '20190331'
            expect(installment2.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment2.principal).to eq 500
            expect(installment2.interest).to eq 12.55
            # 支払い済み
            expect(installment2.paid_principal).to eq 0.0
            expect(installment2.paid_interest).to eq 0.0
            expect(installment2.paid_late_charge).to eq 0.0

            payment3 = contractor.payments.find_by(due_ymd: '20190430')
            expect(payment3.total_amount.to_f).to eq 512.55
            expect(payment3.paid_total_amount.to_f).to eq 0.0

            # Installment 3
            installment3.reload
            expect(installment3.due_ymd).to eq '20190430'
            expect(installment3.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment3.principal).to eq 500
            expect(installment3.interest).to eq 12.55
            # 支払い済み
            expect(installment3.paid_principal).to eq 0.0
            expect(installment3.paid_interest).to eq 0.0
            expect(installment3.paid_late_charge).to eq 0.0
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 100.0
            receive_amount_detail1 = ReceiveAmountDetail.find_by(installment_id: installment1.id)
            expect(receive_amount_detail1).to be_present
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
          end

          it 'select first and last installment but pay 600.0 for the first time' do
            installment1 = contractor.installments.find_by(installment_number: 1)
            installment2 = contractor.installments.find_by(installment_number: 2)
            installment3 = contractor.installments.find_by(installment_number: 3)
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              600.00,
              jv_user,
              'hoge',
              installment_ids: [installment1.id, installment3.id]
            ).call

            expect(result[:remaining_input_amount]).to eq(0.0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay all payment_amount so should not have this
            # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 512.55
            expect(payment1.paid_total_amount.to_f).to eq 512.55
            expect(payment1.status).to eq 'paid'

            # Installment 1
            installment1.reload
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment1.principal).to eq 500
            expect(installment1.interest).to eq 12.55
            # 支払い済み
            expect(installment1.paid_principal).to eq 500
            expect(installment1.paid_interest).to eq 12.55
            expect(installment1.paid_late_charge).to eq 0.0

            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 512.55
            expect(payment2.paid_total_amount.to_f).to eq 0.0

            # Installment 2
            installment2.reload
            expect(installment2.due_ymd).to eq '20190331'
            expect(installment2.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment2.principal).to eq 500
            expect(installment2.interest).to eq 12.55
            # 支払い済み
            expect(installment2.paid_principal).to eq 0.0
            expect(installment2.paid_interest).to eq 0.0
            expect(installment2.paid_late_charge).to eq 0.0

            payment3 = contractor.payments.find_by(due_ymd: '20190430')
            expect(payment3.total_amount.to_f).to eq 512.55
            expect(payment3.paid_total_amount.to_f).to eq 87.45

            # Installment 2
            installment3.reload
            expect(installment3.due_ymd).to eq '20190430'
            expect(installment3.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment3.principal).to eq 500
            expect(installment3.interest).to eq 12.55
            # 支払い済み
            expect(installment3.paid_principal.to_f).to eq(74.9)
            expect(installment3.paid_interest).to eq 12.55
            expect(installment3.paid_late_charge).to eq 0.0
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 600.0
            receive_amount_detail1 = ReceiveAmountDetail.find_by(installment_id: installment1.id)
            expect(receive_amount_detail1).to be_present
            expect(receive_amount_detail1.repayment_ymd).to eq('20190228')
            receive_amount_detail2 = ReceiveAmountDetail.find_by(installment_id: installment3.id)
            expect(receive_amount_detail2).to be_present
            expect(receive_amount_detail2.repayment_ymd).to eq('20190228')
          end

          it 'Pay all 1st time + 100.0' do
            installment1 = contractor.installments.find_by(installment_number: 1)
            installment2 = contractor.installments.find_by(installment_number: 2)
            installment3 = contractor.installments.find_by(installment_number: 3)
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              1637.65,
              jv_user,
              'hoge',
              installment_ids: [installment1.id, installment2.id, installment3.id]
            ).call

            expect(result[:remaining_input_amount]).to eq(100.0)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
            expect(result[:paid_total_exceeded]).to eq(0)
            expect(result[:paid_total_cashback]).to eq(0)

            # # pay exceed so must have this to other loop
            # expect(result[:receive_amount_detail_data_arr].count).to eq(3)
            # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
            #   item[:installment_id] == installment1.id
            # end
            # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
            # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.0)
            # expect(receive_amount_detail_data1[:paid_interest]).to eq(12.55)

            # receive_amount_detail_data2 = result[:receive_amount_detail_data_arr].find do |item|
            #   item[:installment_id] == installment2.id
            # end
            # expect(receive_amount_detail_data2[:installment_id]).to eq(installment2.id)
            # expect(receive_amount_detail_data2[:paid_principal]).to eq(500.0)
            # expect(receive_amount_detail_data2[:paid_interest]).to eq(12.55)

            # receive_amount_detail_data3 = result[:receive_amount_detail_data_arr].find do |item|
            #   item[:installment_id] == installment3.id
            # end
            # expect(receive_amount_detail_data3[:installment_id]).to eq(installment3.id)
            # expect(receive_amount_detail_data3[:paid_principal]).to eq(500.0)
            # expect(receive_amount_detail_data3[:paid_interest]).to eq(12.55)

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq "20190228"

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 512.55
            expect(payment1.paid_total_amount.to_f).to eq 512.55
            expect(payment1.status).to eq 'paid'

            # Installment 1
            installment1.reload
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment1.principal).to eq 500
            expect(installment1.interest).to eq 12.55
            # 支払い済み
            expect(installment1.paid_principal).to eq 500
            expect(installment1.paid_interest).to eq 12.55
            expect(installment1.paid_late_charge).to eq 0.0

            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 512.55
            expect(payment2.paid_total_amount.to_f).to eq 512.55

            # Installment 2
            installment2.reload
            expect(installment2.due_ymd).to eq '20190331'
            expect(installment2.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment2.principal).to eq 500
            expect(installment2.interest).to eq 12.55
            # 支払い済み
            expect(installment2.paid_principal).to eq 500
            expect(installment2.paid_interest).to eq 12.55
            expect(installment2.paid_late_charge).to eq 0.0

            payment3 = contractor.payments.find_by(due_ymd: '20190430')
            expect(payment3.total_amount.to_f).to eq 512.55
            expect(payment3.paid_total_amount.to_f).to eq 512.55

            # Installment 2
            installment3.reload
            expect(installment3.due_ymd).to eq '20190430'
            expect(installment3.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment3.principal).to eq 500
            expect(installment3.interest).to eq 12.55
            # 支払い済み
            expect(installment3.paid_principal).to eq 500
            expect(installment3.paid_interest).to eq 12.55
            expect(installment3.paid_late_charge).to eq 0.0
          end
        end
      end

      describe 'No payment (blank deposit)' do
        describe 'Contractor pool_amount is 0.0' do
          before do
            contractor.update!(pool_amount: 0)
          end
          it 'pool_amount will not be update. (0.0)' do
            result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 100.0, jv_user, 'hoge', installment_ids: []).call

            expect(result[:remaining_input_amount]).to eq(100.0)
            expect(contractor.pool_amount).to eq 0.0
          end
        end

        describe 'Contractor pool_amount will not be update. (50.0)' do
          before do
            contractor.update!(pool_amount: 50.0)
          end
          it 'With a deposit of 100.0, the pool_amount will be 150.0.' do
            result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 100.0, jv_user, 'hoge', installment_ids: []).call

            expect(result[:remaining_input_amount]).to eq(100.0)
            expect(contractor.pool_amount).to eq 50.0
          end
        end
      end
    end
  end

  describe 'case 2 (late charge)' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190309')
      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 512.55, status: 'over_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 512.55, status: 'next_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 512.55, status: 'not_due_yet')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
    end

    it 'pay first installment late charge and then pay all that over_due' do
      installment = order.installments.find_by(due_ymd: '20190228')

      # 遅損金
      expect(installment.calc_late_charge).to eq 13.39

      # 遅損金の支払い
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        13.39,
        jv_user,
        'hoge',
        installment_ids: [installment.id]
      ).call
      installment.reload

      expect(installment.paid_late_charge).to eq 13.39
      expect(installment.calc_remaining_late_charge).to eq 0.0

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # 元本と利息の支払い
      result2 = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        512.55,
        jv_user,
        'hoge',
        installment_ids: [installment.id]
      ).call
      installment.reload

      expect(result2[:remaining_input_amount]).to eq(0.0)
      expect(result2[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result2[:paid_total_exceeded]).to eq(0)
      expect(result2[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result2[:receive_amount_detail_data_arr].count).to eq(0)
      expect(installment.paid_up_ymd).to eq '20190309'
    end

    it 'pay all first installment that over_due' do
      installment = order.installments.find_by(due_ymd: '20190228')

      # 遅損金
      expect(installment.calc_late_charge).to eq 13.39

      # 遅損金の支払い
      # AppropriatePaymentToInstallments.new(contractor, '20190309', 8931.0, jv_user, 'hoge').call
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        525.94,
        jv_user,
        'hoge',
        installment_ids: [installment.id]
      ).call
      installment.reload

      expect(installment.paid_late_charge).to eq 13.39
      expect(installment.calc_remaining_late_charge).to eq 0.0

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)
      # paid_late_charge

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)
      expect(installment.paid_up_ymd).to eq '20190309'
    end

    it 'pay all installment that have 1 over_due' do
      installment1 = contractor.installments.find_by(installment_number: 1)
      installment2 = contractor.installments.find_by(installment_number: 2)
      installment3 = contractor.installments.find_by(installment_number: 3)

      expect(installment1.calc_late_charge).to eq 13.39
      
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        1551.04,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id, installment3.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Order
      order = contractor.orders.first
      expect(order.paid_up_ymd).to eq '20190309'

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 525.94
      expect(payment1.status).to eq 'paid'

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 500
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 13.39

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 512.55

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 500
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 0.0

      payment3 = contractor.payments.find_by(due_ymd: '20190430')
      expect(payment3.total_amount.to_f).to eq 512.55
      expect(payment3.paid_total_amount.to_f).to eq 512.55

      # Installment 2
      installment3.reload
      expect(installment3.due_ymd).to eq '20190430'
      expect(installment3.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment3.principal).to eq 500
      expect(installment3.interest).to eq 12.55
      # 支払い済み
      expect(installment3.paid_principal).to eq 500
      expect(installment3.paid_interest).to eq 12.55
      expect(installment3.paid_late_charge).to eq 0.0
    end

    it 'pay all installment with 600 that have 1 over_due' do
      installment1 = contractor.installments.find_by(installment_number: 1)
      installment2 = contractor.installments.find_by(installment_number: 2)
      installment3 = contractor.installments.find_by(installment_number: 3)

      expect(installment1.calc_late_charge).to eq 13.39
      
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        600.0,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id, installment3.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Order
      order = contractor.orders.first
      expect(order.paid_up_ymd).to eq nil

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 525.94
      expect(payment1.status).to eq 'paid'

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 500
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 13.39

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 74.06

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 61.51
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 0.0
    end

    it 'pay first and last installment with 100 that have 1 over_due' do
      installment1 = contractor.installments.find_by(installment_number: 1)
      installment2 = contractor.installments.find_by(installment_number: 2)
      installment3 = contractor.installments.find_by(installment_number: 3)

      expect(installment1.calc_late_charge).to eq 13.39
      
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        100.0,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment3.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 100.0

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 74.06
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 13.39
    end

    it 'pay all installment that exceed value 100 and have 1 over_due' do
      installment1 = contractor.installments.find_by(installment_number: 1)
      installment2 = contractor.installments.find_by(installment_number: 2)
      installment3 = contractor.installments.find_by(installment_number: 3)

      expect(installment1.calc_late_charge).to eq 13.39
      
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190309',
        1651.04,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id, installment3.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(100.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # expect(result[:receive_amount_detail_data_arr].count).to eq(3)
      # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
      #   item[:installment_id] == installment1.id
      # end
      # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
      # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.0)
      # expect(receive_amount_detail_data1[:paid_interest]).to eq(12.55)
      # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(13.39)

      # receive_amount_detail_data2 = result[:receive_amount_detail_data_arr].find do |item|
      #   item[:installment_id] == installment2.id
      # end
      # expect(receive_amount_detail_data2[:installment_id]).to eq(installment2.id)
      # expect(receive_amount_detail_data2[:paid_principal]).to eq(500.0)
      # expect(receive_amount_detail_data2[:paid_interest]).to eq(12.55)

      # receive_amount_detail_data3 = result[:receive_amount_detail_data_arr].find do |item|
      #   item[:installment_id] == installment3.id
      # end
      # expect(receive_amount_detail_data3[:installment_id]).to eq(installment3.id)
      # expect(receive_amount_detail_data3[:paid_principal]).to eq(500.0)
      # expect(receive_amount_detail_data3[:paid_interest]).to eq(12.55)

      # Order
      order = contractor.orders.first
      expect(order.paid_up_ymd).to eq '20190309'

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 525.94
      expect(payment1.status).to eq 'paid'

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 500
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 13.39

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 512.55

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 500
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 0.0

      payment3 = contractor.payments.find_by(due_ymd: '20190430')
      expect(payment3.total_amount.to_f).to eq 512.55
      expect(payment3.paid_total_amount.to_f).to eq 512.55

      # Installment 2
      installment3.reload
      expect(installment3.due_ymd).to eq '20190430'
      expect(installment3.paid_up_ymd).to eq '20190309'
      # 支払い予定
      expect(installment3.principal).to eq 500
      expect(installment3.interest).to eq 12.55
      # 支払い済み
      expect(installment3.paid_principal).to eq 500
      expect(installment3.paid_interest).to eq 12.55
      expect(installment3.paid_late_charge).to eq 0.0
    end
  end

  describe 'case 3' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190409')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228', paid_up_ymd: '20190228',
        total_amount: 512.55, paid_total_amount: 512.55, status: 'paid')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 512.55, status: 'over_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 512.55, status: 'next_due')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228',  paid_up_ymd: '20190228', principal: 500.00, interest: 12.55, paid_principal: 500.00, paid_interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
    end

    it 'pay the installment that already paid and over_due' do
      installment1 = contractor.installments.find_by(installment_number: 1)
      installment2 = contractor.installments.find_by(installment_number: 2)
      installment3 = contractor.installments.find_by(installment_number: 3)

      # 遅損金
      expect(installment2.calc_late_charge).to eq 10.36

      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190409',
        522.91,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Order
      order = contractor.orders.first
      expect(order.paid_up_ymd).to eq nil

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 522.91

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq '20190409'
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 500
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 10.36
    end
  end

  describe 'case 4' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190409')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 512.55, status: 'over_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 512.55, status: 'over_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 512.55, status: 'not_due_yet')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
    end

    it 'pay first and second order that all over_due' do
      installment1 = order.installments.find_by(due_ymd: '20190228')
      installment2 = order.installments.find_by(due_ymd: '20190331')
      installment3 = order.installments.find_by(due_ymd: '20190430')

      # 遅損金の検証
      expect(installment1.calc_late_charge).to eq 21.23
      expect(installment2.calc_late_charge).to eq 10.36

      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190409',
        1056.69,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 533.78
      expect(payment1.status).to eq 'paid'

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq '20190409'
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 500
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 21.23

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 522.91

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq '20190409'
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 500
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 10.36
    end

    it 'pay first and second order that all over_due (pay 600)' do
      installment1 = order.installments.find_by(due_ymd: '20190228')
      installment2 = order.installments.find_by(due_ymd: '20190331')
      installment3 = order.installments.find_by(due_ymd: '20190430')

      # 遅損金の検証
      expect(installment1.calc_late_charge).to eq 21.23
      expect(installment2.calc_late_charge).to eq 10.36

      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190409',
        600,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 533.78
      expect(payment1.status).to eq 'paid'

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq '20190409'
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 500
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 21.23

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 66.22

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 43.31
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 10.36
    end

    it 'pay first and second order that all over_due (pay exceed 100)' do
      installment1 = order.installments.find_by(due_ymd: '20190228')
      installment2 = order.installments.find_by(due_ymd: '20190331')
      installment3 = order.installments.find_by(due_ymd: '20190430')

      # 遅損金の検証
      expect(installment1.calc_late_charge).to eq 21.23
      expect(installment2.calc_late_charge).to eq 10.36

      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190409',
        1156.69,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(100)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # expect(result[:receive_amount_detail_data_arr].count).to eq(2)
      # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
      #   item[:installment_id] == installment1.id
      # end
      # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
      # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.0)
      # expect(receive_amount_detail_data1[:paid_interest]).to eq(12.55)
      # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(21.23)

      # receive_amount_detail_data2 = result[:receive_amount_detail_data_arr].find do |item|
      #   item[:installment_id] == installment2.id
      # end
      # expect(receive_amount_detail_data2[:installment_id]).to eq(installment2.id)
      # expect(receive_amount_detail_data2[:paid_principal]).to eq(500.0)
      # expect(receive_amount_detail_data2[:paid_interest]).to eq(12.55)
      # expect(receive_amount_detail_data2[:paid_late_charge]).to eq(10.36)

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 533.78
      expect(payment1.status).to eq 'paid'

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq '20190409'
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 500
      expect(installment1.paid_interest).to eq 12.55
      expect(installment1.paid_late_charge).to eq 21.23

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 522.91

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq '20190409'
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 500
      expect(installment2.paid_interest).to eq 12.55
      expect(installment2.paid_late_charge).to eq 10.36
    end

    it 'pay first and second order that all over_due (pay only late_charge but diff payment)' do
      installment1 = order.installments.find_by(due_ymd: '20190228')
      installment2 = order.installments.find_by(due_ymd: '20190331')
      installment3 = order.installments.find_by(due_ymd: '20190430')

      # 遅損金の検証
      expect(installment1.calc_late_charge).to eq 21.23
      expect(installment2.calc_late_charge).to eq 10.36

      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190409',
        31.59,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 512.55
      expect(payment1.paid_total_amount.to_f).to eq 31.59

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 0
      # this must get paid instead of installment2 late charge
      expect(installment1.paid_interest).to eq 10.36
      expect(installment1.paid_late_charge).to eq 21.23

      # Payment 2
      payment2 = contractor.payments.find_by(due_ymd: '20190331')
      expect(payment2.total_amount.to_f).to eq 512.55
      expect(payment2.paid_total_amount.to_f).to eq 0.0

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190331'
      expect(installment2.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment2.principal).to eq 500
      expect(installment2.interest).to eq 12.55
      # 支払い済み
      expect(installment2.paid_principal).to eq 0
      expect(installment2.paid_interest).to eq 0
      expect(installment2.paid_late_charge).to eq 0.0
    end
  end

  describe 'case 5' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }
    let(:order2) {
      FactoryBot.create(
        :order,
        contractor: contractor,
        input_ymd: '20190116',
        purchase_amount: 100,
        dealer: dealer,
        product: product1,
        installment_count: 1,
        purchase_ymd: '20190101',
        order_user: contractor_user
      )
    }

    before do
      BusinessDay.update!(business_ymd: '20190409')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 612.55, status: 'over_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 512.55, status: 'over_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 512.55, status: 'not_due_yet')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 500.00, interest: 12.55)
      FactoryBot.create(:installment, order: order2, payment: payment1,
        due_ymd: '20190228', principal: 100.00)
    end

    it 'pay first and second order that all over_due (pay only late_charge)' do
      installment1 = order.installments.find_by(due_ymd: '20190228')
      installment2 = order2.installments.find_by(due_ymd: '20190228')

      # 遅損金の検証
      expect(installment1.calc_late_charge).to eq 21.23
      expect(installment2.calc_late_charge).to eq 4.14

      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190409',
        25.37,
        jv_user,
        'hoge',
        installment_ids: [installment1.id, installment2.id]
      ).call

      expect(result[:remaining_input_amount]).to eq(0.0)
      expect(result[:paid_exceeded_and_cashback_amount]).to eq(0)
      expect(result[:paid_total_exceeded]).to eq(0)
      expect(result[:paid_total_cashback]).to eq(0)

      # # pay all payment_amount so should not have this
      # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

      # Payment 1
      payment1 = contractor.payments.find_by(due_ymd: '20190228')
      expect(payment1.total_amount.to_f).to eq 612.55
      expect(payment1.paid_total_amount.to_f).to eq 25.37

      # Installment 1
      installment1.reload
      expect(installment1.due_ymd).to eq '20190228'
      expect(installment1.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment1.principal).to eq 500
      expect(installment1.interest).to eq 12.55
      # 支払い済み
      expect(installment1.paid_principal).to eq 0
      expect(installment1.paid_interest).to eq 0
      expect(installment1.paid_late_charge).to eq 21.23

      # Installment 2
      installment2.reload
      expect(installment2.due_ymd).to eq '20190228'
      expect(installment2.paid_up_ymd).to eq nil
      # 支払い予定
      expect(installment2.principal).to eq 100
      # 支払い済み
      expect(installment2.paid_principal).to eq 0
      expect(installment2.paid_late_charge).to eq 4.14
    end
  end

  describe 'Repay late payment multiple times' do
    before do
      order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 341700.02, status: 'next_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 341699.99, status: 'not_due_yet')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 341699.99, status: 'not_due_yet')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
    end
 
    it 'Being able to repay with the correct deposit amount' do
      # 約定日は遅損金なし
      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)
      expect(installment.calc_late_charge).to eq 0.0

      Batch::Daily.exec

      installment.reload
      # 延滞1日目(03/01)。遅損金が発生
      expect(installment.calc_late_charge).to eq 7582.93
      expect(installment.calc_remaining_late_charge).to eq 7582.93

      # 一部の遅損金を支払い
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', 582.93, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge.to_f).to eq 582.93
      expect(installment.calc_remaining_late_charge).to eq 7000.0

      Batch::Daily.exec

      installment.reload
      # 延滞2日目(03/02)
      expect(installment.calc_late_charge).to eq 7751.44
      expect(installment.calc_remaining_late_charge).to eq 7168.51 # 7168.51 = 7751.44 - 582.93

      # 一部の遅損金を支払い
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190302', 1168.51, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge).to eq 1751.44 # 1751.44 = 582.93 + 1168.51
      expect(installment.calc_remaining_late_charge).to eq 6000.0

      # 全ての遅損金を支払い
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190302', 6000.0, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge).to eq 7751.44
      expect(installment.calc_remaining_late_charge).to eq 0.0
    end
  end

  describe 'multiple orders' do
    describe 'Application of late loss charges' do
      before do
        # 注文１
        order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190101',
          input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)

        # 注文２
        order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190102',
          input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 683400.04, status: 'next_due')
        payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
          total_amount: 683399.98, status: 'not_due_yet')
        payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
          total_amount: 683399.98, status: 'not_due_yet')

        FactoryBot.create(:installment, order: order1, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order1, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order1, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

        FactoryBot.create(:installment, order: order2, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order2, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order2, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
      end

      it 'The deposit will be applied from the late loss charge.' do
        order1 = Order.find_by(order_number: '1')
        order2 = Order.find_by(order_number: '2')
        installment1 = order1.installments.find_by(due_ymd: '20190228')
        installment2 = order2.installments.find_by(due_ymd: '20190228')
        Batch::Daily.exec

        payment = Payment.find_by(due_ymd: '20190228')

        # 発生した遅損金
        late_charge = payment.calc_total_late_charge('20190301')

        AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge', installment_ids: [installment1.id, installment2.id]).call

        # 遅損金が全て返済できていること(残りが元本と利息のみなこと)
        expect(payment.reload.remaining_balance).to eq (333333.34 + 8366.68) * 2
      end
    end

    context 'Same input date, different purchase date' do
      before do
        # 注文１
        order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190102', input_ymd: '20190116',
          purchase_amount: 1000000.0, order_user: contractor_user)

        # 注文２
        order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190101', input_ymd: '20190116',
          purchase_amount: 1000000.0, order_user: contractor_user)

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 683400.04, status: 'next_due')
        payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
          total_amount: 683399.98, status: 'not_due_yet')
        payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
          total_amount: 683399.98, status: 'not_due_yet')

        FactoryBot.create(:installment, order: order1, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order1, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order1, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

        FactoryBot.create(:installment, order: order2, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order2, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order2, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
      end

      it 'purchase_ymd must be paid first (order2)' do
        order1 = Order.find_by(order_number: '1')
        order2 = Order.find_by(order_number: '2')
        installment1 = order1.installments.find_by(due_ymd: '20190228')
        installment2 = order2.installments.find_by(due_ymd: '20190228')
        expect(BusinessDay.today_ymd).to eq '20190228'
        # 日付を進めてpayment2をnext_dueにする
        Batch::Daily.exec

        # 遅損金を算出、支払い
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge', installment_ids: [installment1.id, installment2.id]).call
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        expect(late_charge).to eq 0

        # order2のinstallment1を支払い
        order2_installment1 = contractor.orders.find_by(order_number: '2').installments.find_by(installment_number: 1)
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', order2_installment1.remaining_balance, jv_user, 'hoge', installment_ids: [installment1.id, installment2.id]).call
        # order2が先に充当されること
        expect(order2_installment1.reload.paid?).to eq true

        # order1が完済しないこと
        order1_installment1 = contractor.orders.find_by(order_number: '1').installments.find_by(installment_number: 1)
        expect(order1_installment1.paid?).to eq false
      end
    end

    context 'Different input dates, same purchase date' do
      before do
        # 注文１
        order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190101', input_ymd: '20190117',
          purchase_amount: 1000000.0, order_user: contractor_user)

        # 注文２
        order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190101', input_ymd: '20190116',
          purchase_amount: 1000000.0, order_user: contractor_user)

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 683400.04, status: 'next_due')
        payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
          total_amount: 683399.98, status: 'not_due_yet')
        payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
          total_amount: 683399.98, status: 'not_due_yet')

        FactoryBot.create(:installment, order: order1, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order1, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order1, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

        FactoryBot.create(:installment, order: order2, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order2, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order2, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
      end

      it 'input_ymdが早い方(order2)から支払われること' do
        order1 = Order.find_by(order_number: '1')
        order2 = Order.find_by(order_number: '2')
        installment1 = order1.installments.find_by(due_ymd: '20190228')
        installment2 = order2.installments.find_by(due_ymd: '20190228')
        # order2のinstallment1分を支払い
        order2_installment1 = contractor.orders.find_by(order_number: '2').installments.find_by(installment_number: 1)
        AppropriatePaymentToSelectedInstallments.new(
          contractor, '20190228', order2_installment1.remaining_balance, jv_user, 'hoge', installment_ids: [installment1.id, installment2.id]).call
        # order2のinstallment1が完済すること
        expect(order2_installment1.reload.paid?).to eq true

        # order1のinstallment1は支払いがないこと
        order1_installment1 = contractor.orders.find_by(order_number: '1').installments.find_by(installment_number: 1)
        expect(order1_installment1.paid_total_amount).to eq 0
      end
    end

    context 'Same input date, same purchase date' do
      before do
        # 注文１
        order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190101', input_ymd: '20190116',
          purchase_amount: 1000000.0, order_user: contractor_user)

        # 注文２
        order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product2, installment_count: 3, purchase_ymd: '20190101', input_ymd: '20190116',
          purchase_amount: 1000000.0, order_user: contractor_user)

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 683400.04, status: 'next_due')
        payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
          total_amount: 683399.98, status: 'not_due_yet')
        payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
          total_amount: 683399.98, status: 'not_due_yet')

        FactoryBot.create(:installment, order: order1, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order1, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order1, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

        FactoryBot.create(:installment, order: order2, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
        FactoryBot.create(:installment, order: order2, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
        FactoryBot.create(:installment, order: order2, payment: payment3,
          installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
      end

      it 'To be paid in appropriation Payment units.' do
        order1 = Order.find_by(order_number: '1')
        order2 = Order.find_by(order_number: '2')
        installment1 = order1.installments.find_by(due_ymd: '20190228')
        installment2 = order2.installments.find_by(due_ymd: '20190228')
        expect(BusinessDay.today_ymd).to eq '20190228'
        # 日付を進めてpayment2をnext_dueにする
        Batch::Daily.exec

        # 遅損金を算出、支払い
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge', installment_ids: [installment1.id, installment2.id]).call
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        expect(late_charge).to eq 0

        # payment1の残金を支払い
        payment1 = Payment.find_by(contractor: contractor, due_ymd: '20190228')
        AppropriatePaymentToSelectedInstallments.new(
          contractor, '20190301', payment1.remaining_balance, jv_user, 'hoge', installment_ids: [installment1.id, installment2.id]).call

        # payment1のinstallmentが全て支払われていること
        expect(payment1.reload.installments.all?(&:paid?)).to eq true
      end

      it 'To be paid in Second order only.' do
        order1 = Order.find_by(order_number: '1')
        order2 = Order.find_by(order_number: '2')
        installment1 = order1.installments.find_by(due_ymd: '20190228')
        installment2 = order2.installments.find_by(due_ymd: '20190228')
        expect(BusinessDay.today_ymd).to eq '20190228'
        # 日付を進めてpayment2をnext_dueにする
        Batch::Daily.exec

        # 遅損金を算出、支払い
        late_charge = order2.calc_remaining_late_charge
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge', installment_ids: [installment2.id]).call
        late_charge1 = order1.reload.calc_remaining_late_charge
        expect(late_charge1).to eq order1.calc_remaining_late_charge
        late_charge2 = order2.reload.calc_remaining_late_charge
        expect(late_charge2).to eq 0.0

        # payment1の残金を支払い
        payment1 = Payment.find_by(contractor: contractor, due_ymd: '20190228')
        AppropriatePaymentToSelectedInstallments.new(
          contractor, '20190301', installment2.remaining_balance, jv_user, 'hoge', installment_ids: [installment2.id]).call

        # payment1のinstallmentが全て支払われていること
        expect(installment2.reload.remaining_balance).to eq 0
      end
    end

    describe 'installment_history' do
      before do
        BusinessDay.update!(business_ymd: '20221101')

        FactoryBot.create(:installment,
          order: FactoryBot.create(:order, :inputed_date, contractor: contractor),
          payment: FactoryBot.create(:payment, :next_due, contractor: contractor, due_ymd: '20221130'),
          principal: 100,
        )

        FactoryBot.create(:installment,
          order: FactoryBot.create(:order, :inputed_date, contractor: contractor),
          payment: FactoryBot.create(:payment, :not_due_yet, contractor: contractor, due_ymd: '20221231'),
          principal: 200,
        )
      end

      it 'No installation_history record is created for the next payment when the first payment is just paid off.' do
        installment1 = Installment.find_by(due_ymd: '20221130')
        AppropriatePaymentToSelectedInstallments.new(contractor, '20221101', 100, jv_user, 'hoge', installment_ids: [installment1.id]).call

        # 遅損金が全て返済できていること(残りが元本と利息のみなこと)
        expect(Payment.find_by(due_ymd: '20221130').installments.first.installment_histories.count).to eq 2
        expect(Payment.find_by(due_ymd: '20221231').installments.first.installment_histories.count).to eq 1
      end
    end
  end

  describe 'Moving the starting date' do
    before do
      order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 341700.02, status: 'next_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 341699.99, status: 'not_due_yet')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 341699.99, status: 'not_due_yet')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
    end
 
    it 'The starting date moves due to payment of principal.' do
      Batch::Daily.exec(to_ymd: '20190301')

      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)

      expect(installment.calc_late_charge).to eq 7582.93

      # 一部の元本を支払い
      # 16282.95 = 333.34 + 8366.68 + 7582.93
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', 16282.95, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.remaining_principal).to eq 333000.0
    end

    it 'Late losses will be calculated correctly by moving the starting date.' do
      Batch::Daily.exec(to_ymd: '20190301')

      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)

      expect(installment.calc_late_charge).to eq 7582.93

      # 一部の元本を支払い
      # 16282.95 = 333.34 + 8366.68 + 7582.93
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190301', 16282.95, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge).to eq 7582.93
      expect(installment.calc_late_charge).to eq 7582.93
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.remaining_principal).to eq 333000.0

      Batch::Daily.exec(to_ymd: '20190302')

      installment.reload
      expect(installment.paid_late_charge).to eq 7582.93
      expect(installment.calc_late_charge).to eq 7747.14 # 7582.93 + 164.21
      expect(installment.calc_remaining_late_charge).to eq 164.21

      # 遅損金のみの支払い
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190302', 164.21, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge).to eq 7747.14
      expect(installment.calc_late_charge).to eq 7747.14 # 7582.93 + 164.21   ? 7911.35 ?
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.remaining_principal).to eq 333000.0

      # 一部の元本を支払い
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190302', 1000, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge).to eq 7747.14
      expect(installment.calc_late_charge).to eq 7747.14
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.paid_principal).to eq 1333.34
      expect(installment.remaining_principal).to eq 332000.0
      # 支払った金額より下回らないこと
      expect(installment.calc_late_charge('20190302')).to eq 7747.14

      Batch::Daily.exec(to_ymd: '20190303')

      installment.reload
      expect(installment.paid_late_charge).to eq 7747.14
      expect(installment.calc_late_charge).to eq 7910.86 # 7747.14 + 163.72
      expect(installment.calc_remaining_late_charge).to eq 163.72

      Batch::Daily.exec(to_ymd: '20190304')

      installment.reload
      expect(installment.paid_late_charge).to eq 7747.14
      expect(installment.calc_late_charge).to eq 8074.59 # 7747.14 + 327.45
      expect(installment.calc_remaining_late_charge).to eq 327.45

      # 遅損金のみの支払い
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190304', 327.45, jv_user, 'hoge', installment_ids: [installment.id]).call

      installment.reload
      expect(installment.paid_late_charge).to eq 8074.59
      expect(installment.calc_late_charge).to eq 8074.59 # 7747.14 + 327.45
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.remaining_principal).to eq 332000.0

      Batch::Daily.exec(to_ymd: '20190305')

      installment.reload
      # 163.72 = 491.17 - 327.45
      expect(installment.paid_late_charge).to eq 8074.59
      expect(installment.calc_late_charge).to eq 8238.31 # 8238.31 = 8074.59 + 163.72
      expect(installment.calc_remaining_late_charge).to eq 163.72
      expect(installment.remaining_principal).to eq 332000.0
    end
  end

  describe 'cashback, exceeded return' do
    before do
      order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)

      payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 120.0, status: 'next_due')

      FactoryBot.create(:installment, order: order, payment: payment,
        installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 20)
    end

    context 'cashback: 200, exceeded: 0' do
      before do
        contractor.create_gain_cashback_history(200, '20190101', 0)
      end

      it 'Return of paid_cashback that use to result' do
        order = Order.find_by(order_number: '1')
        installment = order.installments.find_by(installment_number: 1)
        result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call

        expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
        expect(result[:paid_total_cashback]).to eq 120

        # # pay all payment_amount so should not have this
        # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

        order = contractor.orders.first
        expect(order.paid_up_ymd).to eq nil

        cashback_use_histories = contractor.cashback_histories.use
        expect(cashback_use_histories.count).to eq 1

        # キャッシュバックが正しく使用されていること
        expect(cashback_use_histories.last.cashback_amount).to eq 120
        expect(cashback_use_histories.last.total).to eq 80
        expect(cashback_use_histories.last.receive_amount_history_id).to be_present

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 0
      end
    end

    context 'cashback: 0, exceeded: 200' do
      before do
        contractor.update!(pool_amount: 200)
      end

      it 'Return of exceeded pool money' do
        order = Order.find_by(order_number: '1')
        installment = order.installments.find_by(installment_number: 1)
        result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call

        # expect(contractor.exceeded_amount).to eq 80
        expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
        expect(result[:paid_total_exceeded]).to eq 120.0
        expect(result[:paid_total_cashback]).to eq 0.0

        # # pay all payment_amount so should not have this
        # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 80
      end
    end

    context 'cashback: 400, exceeded: 200' do
      before do
        contractor.update!(pool_amount: 200)
        contractor.create_gain_cashback_history(400, '20190101', 0)
      end

      it 'Return of exceeded cashback and pool money' do
        order = Order.find_by(order_number: '1')
        installment = order.installments.find_by(installment_number: 1)
        result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call

        expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
        expect(result[:paid_total_exceeded]).to eq 120.0
        expect(result[:paid_total_cashback]).to eq 0.0
        # # pay all payment_amount so should not have this
        # expect(result[:receive_amount_detail_data_arr].count).to eq(0)
        cashback_use_histories = contractor.cashback_histories.use
        expect(cashback_use_histories.count).to eq 0
        expect(contractor.cashback_amount).to eq(400.00)

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 80.0
      end
    end

    context 'payment_amount: 100 cashback: 400, exceeded: 200' do
      before do
        contractor.update!(pool_amount: 200)
        contractor.create_gain_cashback_history(400, '20190101', 0)
      end

      it 'Return of exceeded cashback and pool money' do
        order = Order.find_by(order_number: '1')
        installment = order.installments.find_by(installment_number: 1)
        result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 100, jv_user, 'hoge', installment_ids: [installment.id]).call

        expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
        expect(result[:paid_total_exceeded]).to eq 120.0
        expect(result[:paid_total_cashback]).to eq 0.0

        # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
        # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
        #   item[:installment_id] == installment.id
        # end

        # expect(receive_amount_detail_data1[:installment_id]).to eq installment.id
        # expect(receive_amount_detail_data1[:exceeded_paid_amount]).to eq 120.0
        # expect(receive_amount_detail_data1[:cashback_paid_amount]).to eq 0.0
        # expect(receive_amount_detail_data1[:paid_interest]).to eq 20.0
        # expect(receive_amount_detail_data1[:paid_principal]).to eq 100.0
        cashback_use_histories = contractor.cashback_histories.use
        expect(cashback_use_histories.count).to eq 0
        expect(contractor.cashback_amount).to eq(400.00)

        # Cashback should not use (have exceeded) used correctly
        expect(contractor.cashback_histories.last.cashback_amount).to eq 400.0
        expect(contractor.cashback_histories.last.total).to eq 400.0
        # # be_nil because there need to put remaining payment to next loop
        # expect(contractor.cashback_histories.last.receive_amount_history_id).to eq result[:receive_amount_history_id]

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 80.0
        receive_amount_detail = ReceiveAmountDetail.find_by(installment_id: installment.id)
        expect(receive_amount_detail.receive_amount_history_id).to eq result[:receive_amount_history_id]
      end
    end

    context 'cashback: 120, exceeded: 0 (gain new cashback history because use all cashback)' do
      before do
        contractor.create_gain_cashback_history(120, '20190101', 0)
      end

      it 'Return of paid_cashback that use to result' do
        order = Order.find_by(order_number: '1')
        installment = order.installments.find_by(installment_number: 1)
        result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call

        expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
        expect(result[:paid_total_cashback]).to eq 120

        # # pay all payment_amount so should not have this
        # expect(result[:receive_amount_detail_data_arr].count).to eq(0)

        order = contractor.orders.first
        expect(order.paid_up_ymd).to eq "20190228"

        expect(contractor.cashback_histories.count).to eq 3
        cashback_use_histories = contractor.cashback_histories.use
        expect(cashback_use_histories.count).to eq 1

        # キャッシュバックが正しく使用されていること
        expect(cashback_use_histories.last.cashback_amount).to eq 120
        expect(cashback_use_histories.last.total).to eq 0.0
        expect(cashback_use_histories.last.receive_amount_history_id).to be_present

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 0

        cashback_gain_histories = contractor.cashback_histories.gain
        expect(cashback_gain_histories.count).to eq 2
        # キャッシュバックが正しく使用されていること
        pp order.calc_cashback_amount.to_s
        pp cashback_gain_histories.last.cashback_amount.to_s
        pp cashback_gain_histories.last.total.to_s
        expect(cashback_gain_histories.last.cashback_amount).to eq order.calc_cashback_amount
        expect(cashback_gain_histories.last.total).to eq order.calc_cashback_amount
        expect(cashback_gain_histories.last.receive_amount_history_id).to be_present
        expect(cashback_gain_histories.last.latest).to eq true

      end
    end
  end

  describe 'order.paid_up_ymd' do
    context '2 orders(installment) in 1 payment' do
      let(:order1) { FactoryBot.create(:order, order_number: '1', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
       }
      let(:order2) { FactoryBot.create(:order, order_number: '2', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190102',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
       }

      before do
        payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 2000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order1, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
       
        FactoryBot.create(:installment, order: order2, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
      end

      it 'order.paid_up_ymd is entered when payment is completed for one order (installment)' do
        installment = order1.installments.find_by(installment_number: 1)
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test', installment_ids: [installment.id]).call

        order1.reload
        order2.reload
        payment = Payment.find_by(due_ymd: '20190228')
        expect(payment.status).to eq ('next_due')
        expect(payment.paid_up_ymd).to eq nil
        expect(payment.paid_up_ymd).to eq nil
      end
    end

    context 'Cancellation' do
      let(:order1) { FactoryBot.create(:order, order_number: '1', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190101',
        canceled_at: Time.now, canceled_user: jv_user)
      }
      let(:order2) { FactoryBot.create(:order, order_number: '2', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190102',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
      }

      it 'Canceled orders are not eligible.' do
        payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 1000.0, status: 'next_due')

        installment1 = FactoryBot.create(:installment, order: order1, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0,
          deleted: true)

        installment2 = FactoryBot.create(:installment, order: order2, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 2000.0, jv_user, 'test', installment_ids: [installment1.id, installment2.id]).call

        order1.reload
        order2.reload
        expect(order1.paid_up_ymd).to eq nil
        expect(order2.paid_up_ymd).to eq '20190228'
      end
    end
  end

  describe 'payment' do
    context 'One order(installment) for one payment' do
      let(:order) { FactoryBot.create(:order, order_number: '1', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
      }
      let(:payment) { Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 1000, status: 'next_due') 
      }

      before do
        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
      end

      it 'Once the order (installment) payment is completed, the payment will be paid.' do
        installment = order.installments.find_by(installment_number: 1)
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test', installment_ids: [installment.id]).call

        payment.reload
        expect(payment.status).to eq 'paid'
        expect(payment.paid_up_ymd).to eq '20190228'
        expect(payment.paid_up_operated_ymd).to eq '20190228'
      end
    end

    context '2 orders(installment) in 1 payment' do
      let(:order1) { FactoryBot.create(:order, order_number: '1', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
      }
      let(:order2) { FactoryBot.create(:order, order_number: '2', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190102',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
      }
      let(:payment) { Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 2000.0, status: 'next_due')
      }

      before do
        FactoryBot.create(:installment, order: order1, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
       
        FactoryBot.create(:installment, order: order2, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
      end

      it 'order.paid_up_ymd is entered when payment is completed for one order (installment)' do
        installment = order1.installments.find_by(installment_number: 1)
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test', installment_ids: [installment.id]).call

        payment.reload
        expect(payment.status).to eq 'next_due'
        expect(payment.paid_up_ymd).to eq nil
        expect(payment.paid_up_operated_ymd).to eq nil
      end
    end
  end

  describe 'installment.paid_up_ymd' do
    context 'Pay off two orders on different days' do
      before do
        BusinessDay.update!(business_ymd: '20190228')

        # 注文１(支払い済み)
        order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user,
          paid_up_ymd: '20190227')

        # 注文２
        order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190102',
          input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 2000.0, status: 'next_due', paid_total_amount: 1000.0)

        FactoryBot.create(:installment, order: order1, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 1000, interest: 0,
          paid_up_ymd: '20190227', paid_principal: 1000)
        FactoryBot.create(:installment, order: order2, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 1000, interest: 0)
      end

      it 'paid_up_ymd is not overwritten' do
        installment1 = Order.find_by(order_number: 1).installments.first
        installment2 = Order.find_by(order_number: 2).installments.first

        expect(installment1.paid_up_ymd).to eq '20190227'
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test', installment_ids: [installment2.id]).call
        expect(installment1.reload.paid_up_ymd).to eq '20190227'
        expect(installment2.reload.paid_up_ymd).to eq '20190228'
      end
    end
  end

  describe 'If a late loss occurs and a past date is specified, cashback will be calculated correctly.' do
    before do
      BusinessDay.update!(business_ymd: '20190216')

      FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor,
        cashback_amount: 1016.25, total: 1016.25, exec_ymd: '20190214',
        created_at: '2019-01-01 00:00:00')
    end

    it 'Specify a date before the delay so that the excess of the delay fee will not occur.' do
      order = FactoryBot.create(:order, order_number: '1', contractor: contractor,
        product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190115', purchase_amount: 1000.0, order_user: contractor_user)

      payment = Payment.create!(contractor: contractor, due_ymd: '20190215', total_amount: 1000.0,
        status: 'over_due')

      installment = FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 1000, interest: 0)

      AppropriatePaymentToSelectedInstallments.new(contractor, '20190216', 0, jv_user, 'test', installment_ids: [installment.id]).call
      contractor.reload

      # 上の支払いで得たキャッシュバック
      pp contractor.cashback_histories
      latest_gain = contractor.cashback_histories.gain_latest
      expect(latest_gain.exec_ymd).to eq '20190214'

      # 消し込みの際に遅損金の分のキャッシュバックが使用されていないこと
      expect(contractor.cashback_amount).to eq 0.0
    end
  end

  describe 'exemption' do
    before do
      BusinessDay.update!(business_ymd: '20190316')

      order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
        purchase_amount: 1000.0)
      order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
        purchase_amount: 3000.0)

      payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
        status: 'over_due', total_amount: 2025.1)
      payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315',
        status: 'over_due', total_amount: 1025.1)
      payment3 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190415',
        status: 'next_due', total_amount: 1025.1)

      FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215',
        principal: 1000.0, interest: 0)

      FactoryBot.create(:installment, order: order2, payment: payment1, due_ymd: '20190215',
        principal: 1000.0, interest: 25.1)
      FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190315',
        principal: 1000.0, interest: 25.1)
      FactoryBot.create(:installment, order: order2, payment: payment3, due_ymd: '20190415',
        principal: 1000.0, interest: 25.1)
    end

    it 'No exemption' do
      payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      payment_total_without_late_charge =
                      contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

      # 遅損金の確認
      expect(payment_total - late_charge).to eq payment_total_without_late_charge
      expect(contractor.calc_over_due_amount).to_not eq 0

      order1 = Order.find_by(purchase_amount: 1000.0)
      order2 = Order.find_by(purchase_amount: 3000.0)
      installment1 = order1.installments.find_by(due_ymd: '20190215')
      installment2 = order2.installments.find_by(due_ymd: '20190215')
      installment3 = order2.installments.find_by(due_ymd: '20190315')
      installment4 = order2.installments.find_by(due_ymd: '20190415')

      is_exemption_late_charge = false
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190316',
        payment_total,
        jv_user,
        'test',
        is_exemption_late_charge,
        installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      ).call
      contractor.reload

      expect(contractor.payments.all?(&:paid?)).to eq true
      expect(contractor.calc_over_due_amount).to eq 0
      # Exemption late charges
      expect(Installment.all.all?{|ins| ins.exemption_late_charges.count == 0}).to eq true

      expect(result[:total_exemption_late_charge]).to eq 0
    end

    it 'Waive and write off late loss charges' do
      order1 = Order.find_by(purchase_amount: 1000.0)
      order2 = Order.find_by(purchase_amount: 3000.0)
      installment1 = order1.installments.find_by(due_ymd: '20190215')
      installment2 = order2.installments.find_by(due_ymd: '20190215')
      installment3 = order2.installments.find_by(due_ymd: '20190315')
      installment4 = order2.installments.find_by(due_ymd: '20190415')

      payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      payment_total_without_late_charge =
                      contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

      # 遅損金の確認
      expect(payment_total - late_charge).to eq payment_total_without_late_charge
      expect(contractor.calc_over_due_amount).to_not eq 0

      is_exemption_late_charge = true
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190316',
        payment_total_without_late_charge,
        jv_user,
        'test',
        is_exemption_late_charge,
        installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      ).call
      contractor.reload

      expect(contractor.payments.all?(&:paid?)).to eq true
      expect(contractor.calc_over_due_amount).to eq 0
      expect(Installment.find_by(interest: 0).exemption_late_charges.first.amount).to be > 0
      expect(Installment.find_by(interest: 25.1, due_ymd: '20190215').exemption_late_charges.first.amount).to be > 0
      expect(Installment.find_by(interest: 25.1, due_ymd: '20190315').exemption_late_charges.first.amount).to be > 0

      expect(result[:remaining_input_amount]).to eq 0.0
      expect(result[:total_exemption_late_charge]).to eq late_charge
      expect(contractor.exemption_late_charge_count).to eq 1


      expect(ReceiveAmountHistory.all.last.exemption_late_charge).to be > 0
    end

    it 'Waive and write off late loss charges (exceeded exemption_late_charge)' do
      order1 = Order.find_by(purchase_amount: 1000.0)
      order2 = Order.find_by(purchase_amount: 3000.0)
      installment1 = order1.installments.find_by(due_ymd: '20190215')
      installment2 = order2.installments.find_by(due_ymd: '20190215')
      installment3 = order2.installments.find_by(due_ymd: '20190315')
      installment4 = order2.installments.find_by(due_ymd: '20190415')

      payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      payment_total_without_late_charge =
                      contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

      # 遅損金の確認
      expect(payment_total - late_charge).to eq payment_total_without_late_charge
      expect(contractor.calc_over_due_amount).to_not eq 0

      is_exemption_late_charge = true
      result = AppropriatePaymentToSelectedInstallments.new(
        contractor,
        '20190316',
        payment_total,
        jv_user,
        'test',
        is_exemption_late_charge,
        installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      ).call
      contractor.reload

      expect(contractor.payments.all?(&:paid?)).to eq true
      expect(contractor.calc_over_due_amount).to eq 0
      expect(Installment.find_by(interest: 0).exemption_late_charges.first.amount).to be > 0
      expect(Installment.find_by(interest: 25.1, due_ymd: '20190215').exemption_late_charges.first.amount).to be > 0
      expect(Installment.find_by(interest: 25.1, due_ymd: '20190315').exemption_late_charges.first.amount).to be > 0

      expect(result[:remaining_input_amount]).to eq late_charge
      expect(result[:total_exemption_late_charge]).to eq late_charge

      # ReceiveAmountHistory not create because remaining_amount > 0
      expect(ReceiveAmountHistory.all.last.id).to eq result[:receive_amount_history_id]
      
      # exemption_late_charge_count not count if ReceiveAmountHistory not create
      expect(contractor.exemption_late_charge_count).to eq 1
    end

    context 'Cashback available' do
      it 'Repay with perfect cashback' do
        FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 3050.2)
        order1 = Order.find_by(purchase_amount: 1000.0)
        order2 = Order.find_by(purchase_amount: 3000.0)
        installment1 = order1.installments.find_by(due_ymd: '20190215')
        installment2 = order2.installments.find_by(due_ymd: '20190215')
        installment3 = order2.installments.find_by(due_ymd: '20190315')
        installment4 = order2.installments.find_by(due_ymd: '20190415')
        late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

        # 2つの遅延Paymentをキャッシュバックのみで返済
        is_exemption_late_charge = true
        result = AppropriatePaymentToSelectedInstallments.new(
          contractor,
          '20190316',
          0,
          jv_user,
          'test',
          is_exemption_late_charge,
          installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
        ).call
        contractor.reload

        # 遅損金を含まないキャッシュバック金額のみで返済できていること
        expect(Installment.find_by(due_ymd: '20190215', interest: 0).paid_up_ymd).to eq    '20190316'
        expect(Installment.find_by(due_ymd: '20190215', interest: 25.1).paid_up_ymd).to eq '20190316'
        expect(Installment.find_by(due_ymd: '20190315', interest: 25.1).paid_up_ymd).to eq '20190316'
        expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_up_ymd).to eq nil
        expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_total_amount).to eq 0

        # キャッシュバックが正しく使用されていること
        expect(result[:total_exemption_late_charge]).to eq late_charge
        expect(result[:paid_total_cashback]).to eq 3050.2

        # # poolが発生していないこと
        expect(contractor.exemption_late_charge_count).to eq 1
  
  
        expect(ReceiveAmountHistory.all.last.exemption_late_charge).to be > 0
      end

      it 'Pay back with more cashback' do
        FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 5075.3)

        order1 = Order.find_by(purchase_amount: 1000.0)
        order2 = Order.find_by(purchase_amount: 3000.0)
        installment1 = order1.installments.find_by(due_ymd: '20190215')
        installment2 = order2.installments.find_by(due_ymd: '20190215')
        installment3 = order2.installments.find_by(due_ymd: '20190315')
        installment4 = order2.installments.find_by(due_ymd: '20190415')
        late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

        # 2つの遅延Paymentをキャッシュバックのみで返済
        is_exemption_late_charge = true
        result = AppropriatePaymentToSelectedInstallments.new(
          contractor, '20190316',
          0,
          jv_user,
          'test',
          is_exemption_late_charge,
          installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
        ).call
        contractor.reload

        # 遅損金を含まないキャッシュバック金額のみで返済できていること
        expect(Installment.find_by(due_ymd: '20190215', interest: 0).paid_up_ymd).to eq    '20190316'
        expect(Installment.find_by(due_ymd: '20190215', interest: 25.1).paid_up_ymd).to eq '20190316'
        expect(Installment.find_by(due_ymd: '20190315', interest: 25.1).paid_up_ymd).to eq '20190316'
        expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_up_ymd).to eq '20190316'

        cashback_use_histories = contractor.cashback_histories.use
        expect(cashback_use_histories.count).to eq 1

        # キャッシュバックが正しく使用されていること
        expect(cashback_use_histories.last.cashback_amount).to eq 4075.3
        expect(cashback_use_histories.last.total).to eq 1000.0

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 0
      end
    end
  end

  describe 'Product4' do
    before do
      BusinessDay.update!(business_ymd: '20190315')

      order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190101',
        product: product4, purchase_amount: 1000.0)

      payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315',
        status: 'next_due', total_amount: 1150.0)

      FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190315',
        principal: 1000.0, interest: 150.0)
    end

    it 'No cashback' do
      order1 = Order.find_by(purchase_amount: 1000.0)
      installment1 = order1.installments.find_by(due_ymd: '20190315')
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190315', 1150.0, jv_user, 'test', installment_ids: [installment1.id]).call
      contractor.reload

      expect(contractor.payments.first.paid?).to eq true

      expect(contractor.cashback_amount).to eq 0.0
    end
  end

  describe 'late_charge_start_ymd' do
    context 'No write-off of principal in the past' do
      before do
        order1 = FactoryBot.create(:order, contractor: contractor,
          input_ymd: '20190115', purchase_amount: 1024.6)

        payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'next_due', total_amount: 1024.6)

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215',
          principal: 1000.0, interest: 24.6)
      end

      context 'No erasure of principal' do
        it 'late_charge_start_ymd is not included' do
          installment = Installment.first
          AppropriatePaymentToSelectedInstallments.new(contractor, '20190215', 24.6, jv_user, 'test', installment_ids: [installment.id]).call
          contractor.reload

          installment.reload
          installment_history = installment.target_installment_history('20190215')
          expect(installment_history.late_charge_start_ymd).to eq nil
        end
      end

      context 'There is erasure of the principal.' do
        it 'late_charge_start_ymd must be included' do
          installment = Installment.first
          result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190215', 1024.6, jv_user, 'test', installment_ids: [installment.id]).call
          contractor.reload

          installment.reload
          installment_history = installment.target_installment_history('20190215')
          expect(installment_history.late_charge_start_ymd).to eq '20190216'
        end
      end
    end

    context 'There was a write-off of the principal in the past.' do
      before do
        order1 = FactoryBot.create(:order, contractor: contractor,
          input_ymd: '20190115', purchase_amount: 1024.6)

        payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'next_due', total_amount: 1024.6)

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215',
          principal: 1000.0, interest: 24.6)

        AppropriatePaymentToInstallments.new(contractor, '20190201', 924.6, jv_user, 'test').call
        contractor.reload
      end

      context 'No erasure of principal' do
        context 'over_due' do
          before do
            Payment.first.update!(status: :over_due)
            BusinessDay.update!(business_ymd: '20190216')
          end

          it 'The late_charge_start_ymd of the previous history is moved to the new one.' do
            installment = Installment.first
            late_charge = contractor.orders.first.calc_remaining_late_charge
            expect(late_charge).to_not eq 0

            # 遅損金のみを支払い
            AppropriatePaymentToSelectedInstallments.new(contractor, '20190216', late_charge, jv_user, 'test', installment_ids: [installment.id]).call
            contractor.reload

            installment.reload
            installment_history = installment.target_installment_history('20190216')
            expect(installment_history.late_charge_start_ymd).to eq '20190202'
            expect(installment.paid_total_amount).to eq 924.6 + late_charge
          end
        end
      end

      context 'There is erasure of the principal.' do
        it 'Late_charge_start_ymd is newly entered' do
          installment = Installment.first
          AppropriatePaymentToSelectedInstallments.new(contractor, '20190215', 100, jv_user, 'test', installment_ids: [installment.id]).call
          contractor.reload

          installment.reload
          installment_history = installment.target_installment_history('20190215')
          expect(installment_history.late_charge_start_ymd).to eq '20190216'

          expect(installment.paid_total_amount).to eq 1024.6
        end
      end
    end
  end

  describe 'Update Site Credit Limit when paying principal of Site order' do
    before do
      contractor.create_eligibility(1000, :a_class, 'test', jv_user)
    end

    context 'a' do
      let(:site) { FactoryBot.create(:site, contractor: contractor, site_credit_limit: 1000) }

      before do
        order = FactoryBot.create(:order, contractor: contractor, site: site,
          input_ymd: '20190115', purchase_amount: 1000)

        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'next_due', total_amount: 1000)

        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215',
          principal: 1000.0, interest: 100)
      end

      it 'Site Credit Limit will not be renewed without principal repayment' do
        installment = Installment.first
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190215', 100, jv_user, 'test', installment_ids: [installment.id]).call
        site.reload

        expect(site.site_credit_limit).to eq 1000
      end

      it 'There is principal repayment and the Site Credit Limit is updated.' do
        expect(site.site_credit_limit).to eq 1000
        expect(site.available_balance).to eq 0
        expect(contractor.available_balance).to eq 0

        installment = Installment.first
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190215', 300, jv_user, 'test', installment_ids: [installment.id]).call
        site.reload
        contractor.reload
        
        expect(site.site_credit_limit).to eq 800
        expect(site.available_balance).to eq 0
        expect(contractor.available_balance).to eq 200
      end
    end


    describe 'When repaying the principal of purchases over the limit' do
      let(:site) { FactoryBot.create(:site, contractor: contractor, site_credit_limit: 1000) }

      before do
        order = FactoryBot.create(:order, contractor: contractor, site: site,
          input_ymd: '20190115', purchase_amount: 1050)

        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'next_due', total_amount: 1050)

        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215',
          principal: 1050.0, interest: 0)
      end

      it 'Site Credit Limit must not be negative' do
        installment = Installment.first
        AppropriatePaymentToSelectedInstallments.new(contractor, '20190215', 1040, jv_user, 'test', installment_ids: [installment.id]).call
        site.reload
        contractor.reload

        expect(site.site_credit_limit).to eq 0
        expect(site.available_balance).to eq 0
        expect(contractor.available_balance).to eq 1000
      end
    end
  end

  describe 'Paying off recommitted orders' do
    before do
      order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: nil,
        product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user,
        rescheduled_at: Time.now)

      payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 1000.0, status: 'next_due')

      FactoryBot.create(:installment, order: order, payment: payment,
        installment_number: 1, due_ymd: '20190228', principal: 1000.0, interest: 0.0)
    end

    it 'No errors' do
      installment = Installment.first
      AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 1000, jv_user, 'hoge', installment_ids: [installment.id]).call

      # Order
      order = contractor.orders.first
      expect(order.paid_up_ymd).to eq '20190228'
    end
  end

  describe 'Verification of deposit trail (ReceiveAmountDetail)' do
    before do
      BusinessDay.update!(business_ymd: '20210415')
    end

    describe 'Basic data validation' do
      let(:site) { FactoryBot.create(:site) }
      let(:order) { Order.first }
      let(:installment) { order.installments.first }
      let(:payment) { Payment.first }

      before do
        order = FactoryBot.create(:order, order_number: 'R1', site: site,
          bill_date: 'bill_date_test', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20210315',
          input_ymd: '20210315', purchase_amount: 1000.0, order_user: contractor_user)

        payment = Payment.create!(contractor: contractor, due_ymd: '20210415',
          total_amount: 1100.0, status: 'next_due')

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20210415', principal: 1000.0, interest: 100.0)
      end

      it 'The value is registered correctly' do
        installment = Installment.first
        AppropriatePaymentToSelectedInstallments.new(contractor, '20210415', 1100, jv_user, 'test', installment_ids: [installment.id]).call

        expect(ReceiveAmountDetail.all.count).to eq 1

        receive_amount_detail = ReceiveAmountDetail.first

        expect(receive_amount_detail.order_number).to eq order.order_number
        expect(receive_amount_detail.dealer_name).to eq order.dealer.dealer_name
        expect(receive_amount_detail.dealer_type).to eq order.dealer.dealer_type
        expect(receive_amount_detail.tax_id).to eq contractor.tax_id
        expect(receive_amount_detail.th_company_name).to eq contractor.th_company_name
        expect(receive_amount_detail.en_company_name).to eq contractor.en_company_name
        expect(receive_amount_detail.bill_date).to eq order.bill_date
        expect(receive_amount_detail.site_code).to eq site.site_code
        expect(receive_amount_detail.site_name).to eq site.site_name
        expect(receive_amount_detail.product_name).to eq product1.product_name
        expect(receive_amount_detail.installment_number).to eq installment.installment_number
        expect(receive_amount_detail.due_ymd).to eq installment.due_ymd
        expect(receive_amount_detail.input_ymd).to eq order.input_ymd
        expect(receive_amount_detail.switched_date).to eq nil
        expect(receive_amount_detail.rescheduled_date).to eq nil
        expect(receive_amount_detail.repayment_ymd).to eq '20210415'
        expect(receive_amount_detail.contractor).to eq contractor
        expect(receive_amount_detail.payment).to eq payment
        expect(receive_amount_detail.order).to eq order
        expect(receive_amount_detail.installment).to eq installment
        expect(receive_amount_detail.dealer).to eq dealer
      end

      context 'If the deposit is 0, there will be no write-off or exemption.' do
        it 'If the deposit is 0, there will be no write-off or exemption.' do
          installment = Installment.first
          AppropriatePaymentToSelectedInstallments.new(contractor, '20210415', 0, jv_user, 'test', installment_ids: [installment.id]).call

          expect(ReceiveAmountDetail.all.count).to eq 0
        end
      end
    end

    describe 'Pattern in which erasing does not occur' do
      it 'There is no target and no record is created' do
        AppropriatePaymentToSelectedInstallments.new(contractor, '20210415', 0, jv_user, 'test',  installment_ids: []).call

        expect(ReceiveAmountDetail.all.count).to eq 0
      end
    end

    describe 'Material pattern' do
      # 1Order完済、1Order一部入金/1Order is paid up, 1 order is partially paid
      describe 'pattern 1' do
        before do
          payment = Payment.create!(contractor: contractor, due_ymd: '20210415',
            total_amount: 3150.0, status: 'next_due')

          order1 = FactoryBot.create(:order, order_number: 'R1', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20210315',
            input_ymd: '20210315', purchase_amount: 2000.0, order_user: contractor_user)

          order2 = FactoryBot.create(:order, order_number: 'R2', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20210315',
            input_ymd: '20210315', purchase_amount: 1000.0, order_user: contractor_user)

          FactoryBot.create(:installment, order: order1, payment: payment,
            installment_number: 1, due_ymd: '20210415', principal: 2000.0, interest: 100.0)
          FactoryBot.create(:installment, order: order2, payment: payment,
            installment_number: 1, due_ymd: '20210415', principal: 1000.0, interest: 50.0)
        end

        it 'The data is created correctly' do
          order1 = Order.find_by(order_number: 'R1')
          installment1 = order1.installments.find_by(due_ymd: '20210415')
          order2 = Order.find_by(order_number: 'R2')
          installment2 = order2.installments.find_by(due_ymd: '20210415')
          AppropriatePaymentToSelectedInstallments.new(contractor, '20210415', 2500, jv_user, 'test', installment_ids: [installment1.id, installment2.id]).call

          expect(ReceiveAmountDetail.all.count).to eq 2

          receive_amount_detail1 = ReceiveAmountDetail.first
          receive_amount_detail2 = ReceiveAmountDetail.last

          # receive_amount_detail1
          expect(receive_amount_detail1.receive_amount_history_id.present?).to eq true
          expect(receive_amount_detail1.paid_principal).to eq 2000
          expect(receive_amount_detail1.paid_interest).to eq 100
          expect(receive_amount_detail1.paid_late_charge).to eq 0

          expect(receive_amount_detail1.total_principal).to eq 2000
          expect(receive_amount_detail1.total_interest).to eq 100
          expect(receive_amount_detail1.total_late_charge).to eq 0

          expect(receive_amount_detail1.exceeded_occurred_amount).to eq 0
          expect(receive_amount_detail1.exceeded_paid_amount).to eq 0
          expect(receive_amount_detail1.cashback_paid_amount).to eq 0
          expect(receive_amount_detail1.cashback_occurred_amount).to_not eq 0

          expect(receive_amount_detail1.waive_late_charge).to eq 0

          # receive_amount_detail2
          expect(receive_amount_detail2.receive_amount_history_id.present?).to eq true
          expect(receive_amount_detail2.paid_principal).to eq 350
          expect(receive_amount_detail2.paid_interest).to eq 50
          expect(receive_amount_detail2.paid_late_charge).to eq 0

          expect(receive_amount_detail2.total_principal).to eq 350
          expect(receive_amount_detail2.total_interest).to eq 50
          expect(receive_amount_detail2.total_late_charge).to eq 0

          expect(receive_amount_detail2.exceeded_occurred_amount).to eq 0
          expect(receive_amount_detail2.exceeded_paid_amount).to eq 0
          expect(receive_amount_detail2.cashback_paid_amount).to eq 0
          expect(receive_amount_detail2.cashback_occurred_amount).to eq 0

          expect(receive_amount_detail2.waive_late_charge).to eq 0
        end
      end

      # Exceeded Occurred, Exceeded Occurred Date column is placed in the row of the last order in the order of application among the orders that were applied by the deposit when the Exceeded occurred.
      describe 'pattern 4' do
        let(:dealer) { FactoryBot.create(:cpac_dealer) }

        before do
          site = FactoryBot.create(:site, contractor: contractor)

          payment = Payment.create!(contractor: contractor, due_ymd: '20210415',
            total_amount: 3150.0, status: 'next_due')

          order1 = FactoryBot.create(:order, site: site, order_number: 'R1', contractor: contractor,
            change_product_status: 5, product_changed_at: '2021-03-12 01:23:45',
            dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20210212',
            input_ymd: '20210212', purchase_amount: 3000.0, order_user: contractor_user)

          order2 = FactoryBot.create(:order, site: site, order_number: 'R2', contractor: contractor,
            dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20210212',
            input_ymd: '20210212', purchase_amount: 3000.0, order_user: contractor_user)

          FactoryBot.create(:installment, order: order1, payment: payment,
            installment_number: 1, due_ymd: '20210415', principal: 3000.0, interest: 100.0)
          FactoryBot.create(:installment, order: order2, payment: payment,
            installment_number: 1, due_ymd: '20210415', principal: 3000.0, interest: 100.0)
        end

        it 'The data must not created correctly (need to put exceed value to next loop)' do
          order1 = Order.find_by(order_number: 'R1')
          installment1 = order1.installments.find_by(due_ymd: '20210415')
          order2 = Order.find_by(order_number: 'R2')
          installment2 = order2.installments.find_by(due_ymd: '20210415')
          result = AppropriatePaymentToSelectedInstallments.new(contractor, '20210415', 7200, jv_user, 'test', installment_ids: [installment1.id, installment2.id]).call

          expect(ReceiveAmountDetail.all.count).to eq 2
          expect(result[:remaining_input_amount]).to eq(1000)
        end
      end

      # Partial deposit from Exceeded. Delay Penalty Waiver
      describe 'pattern 5' do
        before do
          site = FactoryBot.create(:site, contractor: contractor)

          payment = Payment.create!(contractor: contractor, due_ymd: '20210430',
            total_amount: 4000.0, status: 'over_due')

          order1 = FactoryBot.create(:order, site: site, order_number: 'R1', contractor: contractor,
            change_product_status: 5, product_changed_at: '2021-03-12 01:23:45',
            dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20210316',
            input_ymd: '20210316', purchase_amount: 4000.0, order_user: contractor_user)

          FactoryBot.create(:installment, order: order1, payment: payment,
            installment_number: 1, due_ymd: '20210430', principal: 4000.0, interest: 0.0)

          contractor.update!(pool_amount: 1000)
        end

        it 'The data is created correctly' do
          BusinessDay.update!(business_ymd: '20210501')

          order1 = Order.find_by(order_number: 'R1')
          installment1 = order1.installments.find_by(due_ymd: '20210430')
          AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20210501',
            0,
            jv_user,
            'test',
            true,
            installment_ids: [installment1.id]).call

          expect(ReceiveAmountDetail.all.count).to eq 1

          receive_amount_detail1 = ReceiveAmountDetail.first

          expect(receive_amount_detail1.exceeded_paid_amount).to eq 1000
          expect(receive_amount_detail1.cashback_paid_amount).to eq 0

          expect(receive_amount_detail1.waive_late_charge).to_not eq 0
        end
      end

      # If the deposit is made when there is no order, and the order is in Exceeded, ReceiveAmountDetail must not create in this loop.
      describe 'pattern 6' do
        it 'The data must not created correctly (need to put exceed value to next loop)' do
          BusinessDay.update!(business_ymd: '20210501')
          result = AppropriatePaymentToSelectedInstallments.new(contractor, '20210501', 100, jv_user, 'test', installment_ids: []).call

          expect(ReceiveAmountDetail.all.count).to eq 1
          expect(result[:remaining_input_amount]).to eq(100)
        end
      end

      # When three installments of Installment for a one-time order are canceled at once.
      describe 'pattern 7' do
        before do
          order1 = FactoryBot.create(:order, order_number: 'R1', contractor: contractor,
            dealer: dealer, product: product2, installment_count: 1, purchase_ymd: '20210412',
            input_ymd: '20210412', purchase_amount: 3000.0, order_user: contractor_user)

          payment1 = Payment.create!(contractor: contractor, due_ymd: '20210515',
            total_amount: 1100.0, status: 'over_due')
          payment2 = Payment.create!(contractor: contractor, due_ymd: '20210615',
            total_amount: 1100.0, status: 'over_due')
          payment3 = Payment.create!(contractor: contractor, due_ymd: '20210715',
            total_amount: 1100.0, status: 'next_due')

          FactoryBot.create(:installment, order: order1, payment: payment1,
            installment_number: 1, due_ymd: '20210515', principal: 1000.0, interest: 100.0)
          FactoryBot.create(:installment, order: order1, payment: payment2,
            installment_number: 2, due_ymd: '20210615', principal: 1000.0, interest: 100.0)
          FactoryBot.create(:installment, order: order1, payment: payment3,
            installment_number: 3, due_ymd: '20210715', principal: 1000.0, interest: 100.0)

          # contractor.update!(pool_amount: 1000)
        end

        it 'The data is created correctly' do
          order1 = Order.find_by(order_number: 'R1')
          installment1 = order1.installments.find_by(due_ymd: '20210515')
          installment2 = order1.installments.find_by(due_ymd: '20210615')
          installment3 = order1.installments.find_by(due_ymd: '20210715')
          BusinessDay.update!(business_ymd: '20210715')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20210715',
            3300,
            jv_user,
            'test',
            true,
            installment_ids: [installment1.id, installment2.id, installment3.id]
          ).call

          expect(ReceiveAmountDetail.all.count).to eq 3
          expect(ReceiveAmountHistory.first.receive_amount_details.count).to eq 3

          receive_amount_detail1 = ReceiveAmountDetail.first
          receive_amount_detail2 = ReceiveAmountDetail.second
          receive_amount_detail3 = ReceiveAmountDetail.last

          expect(receive_amount_detail1.installment_number).to eq 1
          expect(receive_amount_detail2.installment_number).to eq 2
          expect(receive_amount_detail3.installment_number).to eq 3

          expect(receive_amount_detail1.due_ymd).to eq '20210515'
          expect(receive_amount_detail2.due_ymd).to eq '20210615'
          expect(receive_amount_detail3.due_ymd).to eq '20210715'
        end
      end
    end
  end
end
