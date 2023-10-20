# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppropriatePaymentToInstallments, type: :model do
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
          order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)

          payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 1000000.0, status: 'next_due')

          FactoryBot.create(:installment, order: order, payment: payment,
            installment_number: 1, due_ymd: '20190228', principal: 1000000.0, interest: 0.0)
        end

        describe 'Payment on contract date (20190228)' do
          it 'pay in full' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 1000000.0, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq '20190228'

            # Payment
            payment = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment.total_amount).to eq 1000000.0
            expect(payment.paid_total_amount).to eq 1000000.0
            expect(payment.paid_up_ymd).to eq '20190228'
            expect(payment.paid_up_operated_ymd).to eq '20190228'
            expect(payment.status).to eq 'paid'

            # Installment
            installment = contractor.installments.first
            expect(installment.due_ymd).to eq '20190228'
            expect(installment.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment.principal).to eq 1000000.0
            expect(installment.interest).to eq 0.0
            # 支払い済み
            expect(installment.paid_principal).to eq 1000000.0
            expect(installment.paid_interest).to eq 0.0
            expect(installment.paid_late_charge).to eq 0.0

            # Receive Amount History の検証
            expect(contractor.receive_amount_histories.count).to eq 1
            history = contractor.receive_amount_histories.first
            expect(history.receive_ymd).to eq '20190228'
            expect(history.comment).to eq 'hoge'
            expect(history.create_user).to eq jv_user
            expect(history.receive_amount).to eq 1000000.0
          end

          it '一部(900000)を支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 900000.0, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment
            payment = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment.total_amount.to_f).to eq 1000000.0
            expect(payment.paid_total_amount.to_f).to eq 900000.0
            expect(payment.paid_up_ymd).to eq nil
            expect(payment.paid_up_operated_ymd).to eq nil
            expect(payment.status).to eq 'next_due'

            # Installment
            installment = contractor.installments.first
            expect(installment.due_ymd).to eq '20190228'
            expect(installment.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment.principal.to_f).to eq 1000000.0
            expect(installment.interest.to_f).to eq 0.0
            # 支払い済み
            expect(installment.paid_principal.to_f).to eq 900000.0
            expect(installment.paid_interest.to_f).to eq 0.0
            expect(installment.paid_late_charge.to_f).to eq 0.0
          end

          it '余剰(1100000)を支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 1100000.0, jv_user, 'hoge').call
            contractor.reload

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq '20190228'

            # Payment
            payment = contractor.payments.first
            expect(payment.due_ymd).to eq '20190228'
            expect(payment.total_amount).to eq 1000000.0
            expect(payment.paid_total_amount).to eq 1000000.0
            expect(payment.status).to eq 'paid'

            # Installment
            installment = contractor.installments.first
            expect(installment.due_ymd).to eq '20190228'
            expect(installment.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment.principal).to eq 1000000.0
            expect(installment.interest).to eq 0.0
            # 支払い済み
            expect(installment.paid_principal).to eq 1000000.0
            expect(installment.paid_interest).to eq 0.0
            expect(installment.paid_late_charge).to eq 0.0

            expect(contractor.pool_amount).to eq 100000.0
          end
        end
      end

      describe '3 payments' do
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

        describe '約定日(20190228)に支払い' do
          it '1回目を全て支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 341700.02, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 341700.02
            expect(payment1.paid_total_amount.to_f).to eq 341700.02
            expect(payment1.status).to eq 'paid'

            # Installment 1
            installment1 = contractor.installments.find_by(installment_number: 1)
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment1.principal).to eq 333333.34
            expect(installment1.interest).to eq 8366.68
            # 支払い済み
            expect(installment1.paid_principal).to eq 333333.34
            expect(installment1.paid_interest).to eq 8366.68
            expect(installment1.paid_late_charge).to eq 0.0


            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 341699.99
            expect(payment2.paid_total_amount.to_f).to eq 0.0

            # Installment 2
            installment2 = contractor.installments.find_by(installment_number: 2)
            expect(installment2.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment2.principal).to eq 333333.33
            expect(installment2.interest).to eq 8366.66
            # 支払い済み
            expect(installment2.paid_principal.to_f).to eq 0.0
            expect(installment2.paid_interest).to eq 0.0
            expect(installment2.paid_late_charge).to eq 0.0
          end

          it '1回目を 全額 - 100.0 で支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 341600.02, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 341700.02
            expect(payment1.paid_total_amount.to_f).to eq 341600.02
            expect(payment1.status).to eq 'next_due'

            # Installment 1
            installment1 = contractor.installments.find_by(installment_number: 1)
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment1.principal).to eq 333333.34
            expect(installment1.interest).to eq 8366.68
            # 支払い済み
            expect(installment1.paid_principal).to eq 333233.34
            expect(installment1.paid_interest).to eq 8366.68
            expect(installment1.paid_late_charge).to eq 0.0


            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 341699.99
            expect(payment2.paid_total_amount.to_f).to eq 0.0

            # Installment 2
            installment2 = contractor.installments.find_by(installment_number: 2)
            expect(installment2.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment2.principal).to eq 333333.33
            expect(installment2.interest).to eq 8366.66
            # 支払い済み
            expect(installment2.paid_principal.to_f).to eq 0.0
            expect(installment2.paid_interest).to eq 0.0
            expect(installment2.paid_late_charge).to eq 0.0
          end

          it '1回目を利息のみ支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 8366.68, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 341700.02
            expect(payment1.paid_total_amount.to_f).to eq 8366.68
            expect(payment1.status).to eq 'next_due'

            # Installment 1
            installment1 = contractor.installments.find_by(installment_number: 1)
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment1.principal).to eq 333333.34
            expect(installment1.interest).to eq 8366.68
            # 支払い済み
            expect(installment1.paid_principal).to eq 0.0
            expect(installment1.paid_interest).to eq 8366.68
            expect(installment1.paid_late_charge).to eq 0.0

          end

          it '1回目を 100.0 のみ支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 100.0, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 341700.02
            expect(payment1.paid_total_amount.to_f).to eq 100.0
            expect(payment1.status).to eq 'next_due'

            # Installment 1
            installment1 = contractor.installments.find_by(installment_number: 1)
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment1.principal).to eq 333333.34
            expect(installment1.interest).to eq 8366.68
            # 支払い済み
            expect(installment1.paid_principal).to eq 0.0
            expect(installment1.paid_interest).to eq 100.0
            expect(installment1.paid_late_charge).to eq 0.0

          end

          it '1回目 + 100.0 を支払い' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 341800.02, jv_user, 'hoge').call

            # Order
            order = contractor.orders.first
            expect(order.paid_up_ymd).to eq nil

            # Payment 1
            payment1 = contractor.payments.find_by(due_ymd: '20190228')
            expect(payment1.total_amount.to_f).to eq 341700.02
            expect(payment1.paid_total_amount.to_f).to eq 341700.02
            expect(payment1.status).to eq 'paid'

            # Installment 1
            installment1 = contractor.installments.find_by(installment_number: 1)
            expect(installment1.due_ymd).to eq '20190228'
            expect(installment1.paid_up_ymd).to eq '20190228'
            # 支払い予定
            expect(installment1.principal).to eq 333333.34
            expect(installment1.interest).to eq 8366.68
            # 支払い済み
            expect(installment1.paid_principal).to eq 333333.34
            expect(installment1.paid_interest).to eq 8366.68
            expect(installment1.paid_late_charge).to eq 0.0


            # Payment 2
            payment2 = contractor.payments.find_by(due_ymd: '20190331')
            expect(payment2.total_amount.to_f).to eq 341699.99
            expect(payment2.paid_total_amount.to_f).to eq 100.0

            # Installment 2
            installment2 = contractor.installments.find_by(installment_number: 2)
            expect(installment2.paid_up_ymd).to eq nil
            # 支払い予定
            expect(installment2.principal).to eq 333333.33
            expect(installment2.interest).to eq 8366.66
            # 支払い済み
            expect(installment2.paid_principal.to_f).to eq 0.0
            expect(installment2.paid_interest).to eq 100.0
            expect(installment2.paid_late_charge).to eq 0.0

            expect(contractor.pool_amount).to eq 0.0
          end
        end
      end

      describe '支払いなし(空入金)' do
        describe 'Contractorの pool_amount が 0.0' do
          before do
            contractor.update!(pool_amount: 0)
          end
          it '100.0 の入金で pool_amount が100.0 になること' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 100.0, jv_user, 'hoge').call

            expect(contractor.pool_amount).to eq 100.0
          end
        end

        describe 'Contractorの pool_amount が 50.0' do
          before do
            contractor.update!(pool_amount: 50.0)
          end
          it '100.0 の入金で pool_amount が150.0 になること' do
            AppropriatePaymentToInstallments.new(contractor, '20190228', 100.0, jv_user, 'hoge').call

            expect(contractor.pool_amount).to eq 150.0
          end
        end
      end
    end
  end

  describe 'ケース2' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190309')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 341700.02, status: 'over_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 341699.99, status: 'next_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 341699.99, status: 'not_due_yet')

      FactoryBot.create(:installment, order: order, payment: payment1,
        installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
    end

    it '支払いが完了すること' do
      installment = order.installments.find_by(due_ymd: '20190228')

      # 遅損金
      expect(installment.calc_late_charge).to eq 8931.0

      # 遅損金の支払い
      AppropriatePaymentToInstallments.new(contractor, '20190309', 8931.0, jv_user, 'hoge').call
      installment.reload

      expect(installment.paid_late_charge).to eq 8931.0
      expect(installment.calc_remaining_late_charge).to eq 0.0

      # 元本と利息の支払い
      AppropriatePaymentToInstallments.new(contractor, '20190309', 341700.02, jv_user, 'hoge').call
      installment.reload

      expect(installment.paid_up_ymd).to eq '20190309'
    end
  end

  describe 'ケース3' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190409')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228', paid_up_ymd: '20190228',
        total_amount: 341700.02, paid_total_amount: 341700.0, status: 'paid')

      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 341699.99, status: 'over_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 341699.99, status: 'next_due')

      FactoryBot.create(:installment, order: order, payment: payment1, installment_number: 1,
        due_ymd: '20190228', paid_up_ymd: '20190228', principal: 333333.34, interest: 8366.68,
        paid_principal: 333333.34, paid_interest: 8366.68)

      FactoryBot.create(:installment, order: order, payment: payment2,
        installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order, payment: payment3,
        installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
    end

    it '支払いが完了すること' do
      installment = order.installments.find_by(due_ymd: '20190331')

      # 遅損金
      expect(installment.calc_late_charge).to eq 6908.89

      # 遅損金の支払い
      AppropriatePaymentToInstallments.new(contractor, '20190409', 6908.89, jv_user, 'hoge').call
      expect(installment.reload.paid_late_charge).to eq 6908.89

      # 元本と利息の支払い
      AppropriatePaymentToInstallments.new(contractor, '20190409', 341699.99, jv_user, 'hoge').call
      expect(installment.reload.paid_up_ymd).to eq '20190409'
    end
  end

  describe 'ケース4' do
    let(:order) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190409')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 341700.02, status: 'over_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 341699.99, status: 'over_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 341699.99, status: 'next_due')

      FactoryBot.create(:installment, order: order, payment: payment1, installment_number: 1,
        due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order, payment: payment2, installment_number: 2,
        due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order, payment: payment3, installment_number: 3,
        due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
    end

    it '支払いが完了すること' do
      # 入金日: 4/9
      # 支払1
      #   約定日: 2/28
      #   支払額: 341_700.02
      #   遅日数: 84
      #   遅損金: 14_154.80
      # 支払2
      #   約定日: 3/31
      #   支払額: 341_699.99
      #   遅日数: 10
      #   遅損金: 6908.89

      installment1 = order.installments.find_by(due_ymd: '20190228')
      installment2 = order.installments.find_by(due_ymd: '20190331')
      installment3 = order.installments.find_by(due_ymd: '20190430')

      # 遅損金の検証
      expect(installment1.calc_late_charge).to eq 14_154.80

      # 1回目の遅損金の支払い
      input_amount = installment1.calc_late_charge
      AppropriatePaymentToInstallments.new(contractor, '20190409', input_amount, jv_user, 'test').call
      expect(installment1.reload.calc_remaining_late_charge('20190409')).to eq 0.0

      # 1回目の利息の支払い
      input_amount = installment1.interest
      AppropriatePaymentToInstallments.new(contractor, '20190409', input_amount, jv_user, 'test').call
      expect(installment1.reload.remaining_interest).to eq 0.0

      # 1回目の元本の支払い
      input_amount = installment1.principal
      AppropriatePaymentToInstallments.new(contractor, '20190409', input_amount, jv_user, 'test').call
      expect(installment1.reload.remaining_principal).to eq 0.0

      # 1回目の支払いが完了すること
      expect(installment1.reload.paid_up_ymd).to eq '20190409'
      # 2回目の支払いが変わっていないこと
      expect(installment2.reload.paid_total_amount).to eq 0.0

      Batch::Daily.exec(to_ymd: '20190430')

      # 支払2
      #   約定日: 3/31
      #   支払額: 341_699.99
      #   遅日数: 62
      #   遅損金: 10_447.59

      # 遅損金の検証
      expect(installment2.calc_late_charge).to eq 10_447.59

      # 2回目の遅損金の支払い
      input_amount = installment2.calc_late_charge
      AppropriatePaymentToInstallments.new(contractor, '20190430', input_amount, jv_user, 'test').call
      expect(installment2.reload.calc_remaining_late_charge('20190430')).to eq 0.0

      # 2回目の利息の支払い
      input_amount = installment2.interest
      AppropriatePaymentToInstallments.new(contractor, '20190430', input_amount, jv_user, 'test').call
      expect(installment2.reload.remaining_interest).to eq 0.0

      # 2回目の元本の支払い
      input_amount = installment2.principal
      AppropriatePaymentToInstallments.new(contractor, '20190430', input_amount, jv_user, 'test').call
      expect(installment2.reload.remaining_principal).to eq 0.0

      # 2回目の支払いが完了すること
      expect(installment2.reload.paid_up_ymd).to eq '20190430'
      # 3回目の支払いが変わっていないこと
      expect(installment3.reload.paid_total_amount).to eq 0.0

      # 支払い3
      input_amount = installment3.remaining_balance
      AppropriatePaymentToInstallments.new(contractor, '20190430', input_amount, jv_user, 'test').call
      contractor.reload
      expect(installment3.reload.paid?).to eq true
      expect(contractor.payments.all?(&:paid?)).to eq true
      expect(contractor.exceeded_amount).to eq 0.0
    end
  end

  describe 'ケース5 参考1' do
    let(:order1) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }
    let(:order2) {
      FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190105',
        input_ymd: '20190120', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190309')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 683400.04, status: 'over_due')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 683399.98, status: 'next_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 683399.98, status: 'not_due_yet')

      # Order1
      FactoryBot.create(:installment, order: order1, payment: payment1, installment_number: 1,
        due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order1, payment: payment2, installment_number: 2,
        due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order1, payment: payment3, installment_number: 3,
        due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

      # Order2
      FactoryBot.create(:installment, order: order2, payment: payment1, installment_number: 1,
        due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order2, payment: payment2, installment_number: 2,
        due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order2, payment: payment3, installment_number: 3,
        due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
    end

    it '支払いが完了すること' do
      # Order1
      order1_installment1 = order1.installments.find_by(due_ymd: '20190228')
      order1_installment2 = order1.installments.find_by(due_ymd: '20190331')
      order1_installment3 = order1.installments.find_by(due_ymd: '20190430')
      # Order2
      order2_installment1 = order2.installments.find_by(due_ymd: '20190228')
      order2_installment2 = order2.installments.find_by(due_ymd: '20190331')
      order2_installment3 = order2.installments.find_by(due_ymd: '20190430')

      ## 遅損金の支払い
      # 1回目の Order1
      input_amount = order1_installment1.calc_late_charge
      AppropriatePaymentToInstallments.new(contractor, '20190309', input_amount, jv_user, 'test').call
      expect(order1_installment1.reload.calc_remaining_late_charge('20190309')).to eq 0.0
      # 1回目の Order2
      input_amount = order2_installment1.calc_late_charge
      AppropriatePaymentToInstallments.new(contractor, '20190309', input_amount, jv_user, 'test').call
      expect(order2_installment1.reload.calc_remaining_late_charge('20190309')).to eq 0.0

      ## Order1 の利息と元本の支払い
      # 1回目の利息
      input_amount = order1_installment1.interest
      AppropriatePaymentToInstallments.new(contractor, '20190309', input_amount, jv_user, 'test').call
      expect(order1_installment1.reload.remaining_interest).to eq 0.0
      # 1回目の元本
      input_amount = order1_installment1.principal
      AppropriatePaymentToInstallments.new(contractor, '20190309', input_amount, jv_user, 'test').call
      expect(order1_installment1.reload.remaining_principal).to eq 0.0

      # 1回目の支払いが完了すること
      expect(order1_installment1.reload.paid_up_ymd).to eq '20190309'
      # 2回目の支払いが変わっていないこと
      order2_installment1.reload
      expect(order2_installment1.paid_total_amount).to eq order2_installment1.paid_late_charge.to_f
    end
  end

  describe 'ケース5 参考2' do
    let(:order1) {
      FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190101',
        input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
    }
    let(:order2) {
      FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190105',
        input_ymd: '20190120', purchase_amount: 1000000.00, order_user: contractor_user)
    }
    let(:order3) {
      FactoryBot.create(:order, order_number: '3', contractor: contractor, dealer: dealer,
        product: product2, installment_count: 3, purchase_ymd: '20190128',
        input_ymd: '20190210', purchase_amount: 1000000.00, order_user: contractor_user)
    }

    before do
      BusinessDay.update!(business_ymd: '20190409')

      payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
        total_amount: 683400.04, paid_total_amount: 683400.04,
        paid_up_ymd: '20190228', paid_up_operated_ymd: '20190228', status: 'paid')
      payment2 = Payment.create!(contractor: contractor, due_ymd: '20190315',
        total_amount: 341700.02, status: 'over_due')
      payment3 = Payment.create!(contractor: contractor, due_ymd: '20190331',
        total_amount: 683399.98, status: 'over_due')
      payment4 = Payment.create!(contractor: contractor, due_ymd: '20190415',
        total_amount: 341699.99, status: 'next_due')
      payment5 = Payment.create!(contractor: contractor, due_ymd: '20190430',
        total_amount: 683399.98, status: 'next_due')
      payment6 = Payment.create!(contractor: contractor, due_ymd: '20190515',
        total_amount: 341699.99, status: 'not_due_yet')

      # Order1
      FactoryBot.create(:installment, order: order1, payment: payment1, installment_number: 1,
        due_ymd: '20190228', paid_up_ymd: '20190228', principal: 333333.34, interest: 8366.68,
        paid_principal: 333333.34, paid_interest: 8366.68)
      FactoryBot.create(:installment, order: order1, payment: payment3, installment_number: 2,
        due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order1, payment: payment5, installment_number: 3,
        due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

      # Order2
      FactoryBot.create(:installment, order: order2, payment: payment1, installment_number: 1,
        due_ymd: '20190228', paid_up_ymd: '20190228', principal: 333333.34, interest: 8366.68,
        paid_principal: 333333.34, paid_interest: 8366.68)
      FactoryBot.create(:installment, order: order2, payment: payment3, installment_number: 2,
        due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order2, payment: payment5, installment_number: 3,
        due_ymd: '20190430', principal: 333333.33, interest: 8366.66)

      # Order3
      FactoryBot.create(:installment, order: order3, payment: payment2, installment_number: 1,
        due_ymd: '20190315', principal: 333333.34, interest: 8366.68)
      FactoryBot.create(:installment, order: order3, payment: payment4, installment_number: 2,
        due_ymd: '20190415', principal: 333333.33, interest: 8366.66)
      FactoryBot.create(:installment, order: order3, payment: payment6, installment_number: 3,
        due_ymd: '20190515', principal: 333333.33, interest: 8366.66)
    end

    it '最初に商品Cの支払いが完了すること' do
      # Order3
      order3_installment1 = order3.installments.find_by(due_ymd: '20190315')

      ## 商品Cの支払い
      # 遅損金
      input_amount = order3_installment1.calc_late_charge
      AppropriatePaymentToInstallments.new(contractor, '20190409', input_amount, jv_user, 'test').call
      expect(order3_installment1.reload.calc_remaining_late_charge('20190409')).to eq 0.0
      # 利息
      input_amount = order3_installment1.interest
      AppropriatePaymentToInstallments.new(contractor, '20190409', input_amount, jv_user, 'test').call
      expect(order3_installment1.reload.remaining_interest).to eq 0.0
      # 元本
      input_amount = order3_installment1.principal
      AppropriatePaymentToInstallments.new(contractor, '20190409', input_amount, jv_user, 'test').call
      expect(order3_installment1.reload.remaining_principal).to eq 0.0
      # 支払いが完了すること
      expect(order3_installment1.reload.paid_up_ymd).to eq '20190409'
    end
  end

  describe '特殊ケース' do
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
 
    it '時系列のcalc_late_chargeが減らないこと' do
      # 利息を返した場合にcalc_late_chargeが減る場合に、
      # 取得される遅損金が前日以前より減らないことを検証

      # 遅損金が時系列で減るパターン

      # 約定日は遅損金なし
      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)
      expect(installment.calc_late_charge).to eq 0.0

      Batch::Daily.exec

      installment.reload
      # 延滞1日目。遅損金が発生
      expect(installment.calc_late_charge).to eq 7582.93

      # 遅損金と利息を支払い
      # 15949.61 = 7582.93 + 8366.68
      AppropriatePaymentToInstallments.new(contractor, '20190301', 15949.61, jv_user, 'hoge').call
      # 遅損金の支払いはなくなる
      installment.reload
      expect(installment.paid_late_charge).to eq 7582.93
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.paid_interest).to eq 8366.68
      expect(installment.remaining_interest).to eq 0.0
      expect(installment.paid_principal).to eq 0.0

      Batch::Daily.exec

      installment.reload
      # 延滞2日目
      # 本来は 支払(元本333333.34 + 利息0) * 18% * (46/365) = 7561.64 の遅損金だが、
      # 利息がない分、前日に支払った遅損金よりも低くなるので、支払った金額を下回らない様に調整される
      expect(installment.calc_late_charge).to_not eq 7561.64 # 本来はこの額だが、
      expect(installment.calc_late_charge).to eq 7582.93     # 支払い済を下回らないこと

      # 元本の支払いで完了
      AppropriatePaymentToInstallments.new(contractor, '20190302', 333333.34, jv_user, 'hoge').call

      installment.reload
      expect(installment.paid_late_charge).to eq 7582.93
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.paid_principal).to eq 333333.34
      expect(installment.remaining_principal).to eq 0.0
      expect(installment.paid_up_ymd).to eq '20190302'
    end
  end

  describe '利息のみを充当した日を指定して検証' do
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
 
    it '複合パターンの検証' do
      # 約定日は遅損金なし
      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)
      expect(installment.calc_late_charge).to eq 0.0

      Batch::Daily.exec(to_ymd: '20190301')

      expect(installment.calc_paid_late_charge).to eq 0.0
      expect(installment.calc_late_charge).to eq 7582.93

      # 遅損金と一部の利息を支払い
      # 7949.61 = 7582.93 + 366.68
      AppropriatePaymentToInstallments.new(contractor, '20190301', 7949.61, jv_user, 'hoge').call
      installment.reload

      # 利息が減ったのでその分遅損金も減るが、支払った
      expect(installment.calc_paid_late_charge).to eq 7582.93
      expect(installment.calc_late_charge).to eq 7582.93

      Batch::Daily.exec(to_ymd: '20190302')
      installment.reload

      expect(installment.calc_paid_late_charge).to eq 7582.93
      expect(installment.calc_late_charge).to eq 7743.12
      expect(installment.calc_remaining_late_charge).to eq 160.19

      # 遅損金と一部の利息を支払い
      # 1160.19 = 160.19 + 1000
      AppropriatePaymentToInstallments.new(contractor, '20190302', 1160.19, jv_user, 'hoge').call
      installment.reload

      expect(installment.calc_paid_late_charge).to eq 7743.12
      expect(installment.calc_late_charge).to eq 7743.12

      expect(installment.remaining_interest).to eq 7000.0

      # 2日進める
      Batch::Daily.exec(to_ymd: '20190304')
      installment.reload

      # 支払い前
      expect(installment.calc_paid_late_charge).to eq 7743.12
      expect(installment.calc_late_charge).to eq 8056.1
      expect(installment.calc_remaining_late_charge).to eq 312.98

      # 前日の金額
      expect(installment.calc_paid_late_charge('20190303')).to eq 7743.12
      expect(installment.calc_late_charge('20190303')).to eq 7888.27
      expect(installment.calc_remaining_late_charge('20190303')).to eq 145.15

      # 前日で遅損金のみを払う
      AppropriatePaymentToInstallments.new(contractor, '20190303', 145.15, jv_user, 'hoge').call

      # 支払い後(1日分の遅損が発生)
      expect(installment.calc_paid_late_charge).to eq 7888.27
      expect(installment.calc_late_charge).to eq 8056.1
      expect(installment.calc_remaining_late_charge).to eq 167.83

      Batch::Daily.exec(to_ymd: '20190305')
      installment.reload

      expect(installment.calc_paid_late_charge).to eq 7888.27
      expect(installment.calc_late_charge).to eq 8223.94
      expect(installment.calc_remaining_late_charge).to eq 335.67
      expect(installment.remaining_interest).to eq 7000.0

      # 元本の１部を払う
      # 7669.01 = 333.34 + (7335.67 = 335.67 + 7000.0)
      AppropriatePaymentToInstallments.new(contractor, '20190305', 7669.01, jv_user, 'hoge').call
      installment.reload

      expect(installment.calc_paid_late_charge).to eq 8223.94
      expect(installment.calc_late_charge).to eq 8223.94
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.remaining_interest).to eq 0.0
      expect(installment.paid_principal).to eq 333.34
      expect(installment.calc_remaining_amount_without_late_charge('20190305')).to eq 333000.0

      expect(installment.calc_late_charge('20190304')).to eq 8056.1
      expect(installment.calc_late_charge('20190303')).to eq 7888.27
      expect(installment.calc_late_charge('20190302')).to eq 7743.12
      expect(installment.calc_late_charge('20190301')).to eq 7582.93
      expect(installment.calc_late_charge('20190228')).to eq 0.0
    end
  end

  describe '遅損金を複数回で返済' do
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
 
    it '正しい入金額で返済ができること' do
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
      AppropriatePaymentToInstallments.new(contractor, '20190301', 582.93, jv_user, 'hoge').call

      installment.reload
      expect(installment.paid_late_charge.to_f).to eq 582.93
      expect(installment.calc_remaining_late_charge).to eq 7000.0

      Batch::Daily.exec

      installment.reload
      # 延滞2日目(03/02)
      expect(installment.calc_late_charge).to eq 7751.44
      expect(installment.calc_remaining_late_charge).to eq 7168.51 # 7168.51 = 7751.44 - 582.93

      # 一部の遅損金を支払い
      AppropriatePaymentToInstallments.new(contractor, '20190302', 1168.51, jv_user, 'hoge').call

      installment.reload
      expect(installment.paid_late_charge).to eq 1751.44 # 1751.44 = 582.93 + 1168.51
      expect(installment.calc_remaining_late_charge).to eq 6000.0

      # 全ての遅損金を支払い
      AppropriatePaymentToInstallments.new(contractor, '20190302', 6000.0, jv_user, 'hoge').call

      installment.reload
      expect(installment.paid_late_charge).to eq 7751.44
      expect(installment.calc_remaining_late_charge).to eq 0.0
    end
  end

  describe '複数の注文' do
    describe '遅損金の充当' do
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

      it '入金が遅損金から充当されること' do
        Batch::Daily.exec

        payment = Payment.find_by(due_ymd: '20190228')

        # 発生した遅損金
        late_charge = payment.calc_total_late_charge('20190301')

        AppropriatePaymentToInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge').call

        # 遅損金が全て返済できていること(残りが元本と利息のみなこと)
        expect(payment.reload.remaining_balance).to eq (333333.34 + 8366.68) * 2
      end
    end

    context '同じ入力日、異なる購入日' do
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

      it 'purchase_ymdが早い方(order2)から支払われること' do
        expect(BusinessDay.today_ymd).to eq '20190228'
        # 日付を進めてpayment2をnext_dueにする
        Batch::Daily.exec
        # expect(Payment.find_by(contractor: contractor, due_ymd: '20190331').status).to eq 'next_due'

        # 遅損金を算出、支払い
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        AppropriatePaymentToInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge').call
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        expect(late_charge).to eq 0

        # order2のinstallment1を支払い
        order2_installment1 = contractor.orders.find_by(order_number: '2').installments.find_by(installment_number: 1)
        AppropriatePaymentToInstallments.new(
          contractor, '20190301', order2_installment1.remaining_balance, jv_user, 'hoge').call
        # order2が先に充当されること
        expect(order2_installment1.reload.paid?).to eq true

        # order1が完済しないこと
        order1_installment1 = contractor.orders.find_by(order_number: '1').installments.find_by(installment_number: 1)
        expect(order1_installment1.paid?).to eq false
      end
    end

    context '異なる入力日、同じ購入日' do
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
        # order2のinstallment1分を支払い
        order2_installment1 = contractor.orders.find_by(order_number: '2').installments.find_by(installment_number: 1)
        AppropriatePaymentToInstallments.new(
          contractor, '20190228', order2_installment1.remaining_balance, jv_user, 'hoge').call
        # order2のinstallment1が完済すること
        expect(order2_installment1.reload.paid?).to eq true

        # order1のinstallment1は支払いがないこと
        order1_installment1 = contractor.orders.find_by(order_number: '1').installments.find_by(installment_number: 1)
        expect(order1_installment1.paid_total_amount).to eq 0
      end
    end

    context '同じ入力日、同じ購入日' do
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

      it '充当のPaymentの単位で支払われること' do
        expect(BusinessDay.today_ymd).to eq '20190228'
        # 日付を進めてpayment2をnext_dueにする
        Batch::Daily.exec
        # expect(Payment.find_by(contractor: contractor, due_ymd: '20190331').status).to eq 'next_due'

        # 遅損金を算出、支払い
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        AppropriatePaymentToInstallments.new(contractor, '20190301', late_charge, jv_user, 'hoge').call
        late_charge = contractor.orders.inject(0){|sum, order| sum + order.calc_remaining_late_charge}
        expect(late_charge).to eq 0

        # payment1の残金を支払い
        payment1 = Payment.find_by(contractor: contractor, due_ymd: '20190228')
        AppropriatePaymentToInstallments.new(
          contractor, '20190301', payment1.remaining_balance, jv_user, 'hoge').call

        # payment1のinstallmentが全て支払われていること
        expect(payment1.reload.installments.all?(&:paid?)).to eq true
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

      it '最初のpaymentをちょうどで完済した際に、次のpaymentのinstallment_historyのレコードが作られないこと' do
        AppropriatePaymentToInstallments.new(contractor, '20221101', 100, jv_user, 'hoge').call

        # 遅損金が全て返済できていること(残りが元本と利息のみなこと)
        expect(Payment.find_by(due_ymd: '20221231').installments.first.installment_histories.count).to eq 1
      end
    end
  end

  describe '起算日の移動' do
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
 
    it '元本の支払いで起算日が移動すること' do
      Batch::Daily.exec(to_ymd: '20190301')

      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)

      expect(installment.calc_late_charge).to eq 7582.93

      # 一部の元本を支払い
      # 16282.95 = 333.34 + 8366.68 + 7582.93
      AppropriatePaymentToInstallments.new(contractor, '20190301', 16282.95, jv_user, 'hoge').call

      installment.reload
      expect(installment.remaining_principal).to eq 333000.0
    end

    it '起算日の移動で遅損金が正しく算出されること' do
      Batch::Daily.exec(to_ymd: '20190301')

      order = contractor.orders.first
      installment = order.installments.find_by(installment_number: 1)

      expect(installment.calc_late_charge).to eq 7582.93

      # 一部の元本を支払い
      # 16282.95 = 333.34 + 8366.68 + 7582.93
      AppropriatePaymentToInstallments.new(contractor, '20190301', 16282.95, jv_user, 'hoge').call

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
      AppropriatePaymentToInstallments.new(contractor, '20190302', 164.21, jv_user, 'hoge').call

      installment.reload
      expect(installment.paid_late_charge).to eq 7747.14
      expect(installment.calc_late_charge).to eq 7747.14 # 7582.93 + 164.21   ? 7911.35 ?
      expect(installment.calc_remaining_late_charge).to eq 0.0
      expect(installment.remaining_principal).to eq 333000.0

      # 一部の元本を支払い
      AppropriatePaymentToInstallments.new(contractor, '20190302', 1000, jv_user, 'hoge').call

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
      AppropriatePaymentToInstallments.new(contractor, '20190304', 327.45, jv_user, 'hoge').call

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

  describe 'キャッシュバック' do
    describe '締め日が15日' do
      before do
        order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          input_ymd: '20190115', purchase_amount: 1070000.0, order_user: contractor_user)

        payment = Payment.create!(contractor: contractor, due_ymd: '20190215',
          total_amount: 1070000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 1070000.0, interest: 0.0)
      end

      it '期日内の返済でポイントがもらえること' do
        expect(contractor.cashback_amount).to eq 0.0

        AppropriatePaymentToInstallments.new(contractor, '20190215', 1070000.0, jv_user, 'hoge').call
        contractor.reload

        expect(contractor.cashback_amount).to eq 5000.0
      end

      it '期日外の返済でポイントがもらえないこと' do
        expect(contractor.cashback_amount).to eq 0.0

        remaining_balance = contractor.payments.first.remaining_balance('20190216')

        AppropriatePaymentToInstallments.new(contractor, '20190216', remaining_balance, jv_user, 'hoge').call
        contractor.reload

        expect(contractor.payments.first.paid?).to eq true

        expect(contractor.cashback_amount).to eq 0.0
      end

      it '受け取った合計金額が正しいこと(正しく加算されること)' do
        # キャッシュバック獲得履歴を作成
        contractor.create_gain_cashback_history(100.0, '20190101', 0)

        expect(contractor.cashback_amount).to eq 100.0

        AppropriatePaymentToInstallments.new(contractor, '20190131', 1070000.0, jv_user, 'hoge').call
        contractor.reload

        # 元々あったキャッシュバックはプール金へ移動する
        expect(contractor.cashback_amount).to eq 5000.0
        expect(contractor.pool_amount).to eq 100.0
      end
    end

    describe '締め日が月末' do
      before do
        order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          input_ymd: '20190116', purchase_amount: 1070000.0, order_user: contractor_user)

        payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 1070000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1070000.0, interest: 0.0)
      end

      it '期日内の返済でポイントがもらえること' do
        expect(contractor.cashback_amount).to eq 0.0

        AppropriatePaymentToInstallments.new(contractor, '20190228', 1070000.0, jv_user, 'hoge').call
        contractor.reload

        expect(contractor.cashback_amount).to eq 5000.0
      end

      it '期日外の返済でポイントがもらえないこと' do
        BusinessDay.update!(business_ymd: '20190301')
        expect(contractor.cashback_amount).to eq 0.0

        remaining_balance = contractor.payments.first.remaining_balance('20190301')

        AppropriatePaymentToInstallments.new(contractor, '20190301', remaining_balance, jv_user, 'hoge').call
        contractor.reload

        expect(contractor.payments.first.paid?).to eq true

        expect(contractor.cashback_amount).to eq 0.0
      end
    end

    describe '履歴' do
      before do
        order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)

        payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 1000000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000000.0, interest: 0.0)
      end

      it '使用する cashbackが 0 で使用履歴が作成されないこと(履歴なし)' do
        expect(contractor.cashback_amount).to eq 0.0
        expect(contractor.cashback_histories.count).to eq 0

        AppropriatePaymentToInstallments.new(contractor, '20190201', 100.0, jv_user, 'hoge').call

        expect(contractor.cashback_histories.count).to eq 0
      end

      it '使用する cashbackが 0 で使用履歴が作成されないこと(履歴あり)' do
        contractor.create_gain_cashback_history(10.0, '20190101', 0)
        contractor.create_use_cashback_history(10.0, '20190101')

        expect(contractor.cashback_amount).to eq 0.0
        expect(contractor.cashback_histories.count).to eq 2

        AppropriatePaymentToInstallments.new(contractor, '20190201', 100.0, jv_user, 'hoge').call

        expect(contractor.cashback_histories.count).to eq 2
      end

      it '使用する  cashbackが 10 で使用履歴が作成されること' do
        # キャッシュバック獲得履歴を作成
        contractor.create_gain_cashback_history(10.0, '20190101', 0)

        expect(contractor.cashback_amount).to eq 10.0
        expect(contractor.cashback_histories.count).to eq 1

        AppropriatePaymentToInstallments.new(contractor, '20190201', 100.0, jv_user, 'hoge').call

        expect(contractor.cashback_histories.count).to eq 2
        expect(contractor.cashback_amount).to eq 0.0
        expect(contractor.latest_cashback.point_type).to eq 'use'
      end
    end

    describe '使用タイミング' do
      # order1が支払い済み
      before do
        order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190101',
          input_ymd: '20190116', purchase_amount: 10000.0, order_user: contractor_user,
          paid_up_ymd: '20190215')
        order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190102',
          input_ymd: '20190117', purchase_amount: 10000.0, order_user: contractor_user)
        order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, dealer: dealer,
          product: product1, installment_count: 1, purchase_ymd: '20190103',
          input_ymd: '20190201', purchase_amount: 10000.0, order_user: contractor_user)

        payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 20000.0, status: 'next_due', paid_total_amount: 10000.0)
        payment2 = Payment.create!(contractor: contractor, due_ymd: '20190315',
          total_amount: 10000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order1, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 10000.0, interest: 0.0,
          paid_principal: 10000.0, paid_up_ymd: '20190215')
        FactoryBot.create(:installment, order: order2, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 10000.0, interest: 0.0)
        FactoryBot.create(:installment, order: order3, payment: payment2,
          installment_number: 1, due_ymd: '20190228', principal: 10000.0, interest: 0.0)

        FactoryBot.create(:cashback_history, :gain, :latest, order: order1)
      end

      it 'キャッシュバックを獲得したpaymentでそのキャッシュバックが使用されないこと' do
        # payment1が完済できない金額を入金(payment1で得たキャッシュバックが使用されないことを検証する)
        AppropriatePaymentToInstallments.new(contractor, '20190228', 9999.0, jv_user, 'hoge').call
        contractor.reload
        expect(contractor.payments.first.paid_up_ymd).to eq nil

        # payment1が完済されないので、payment2にキャッシュバックの支払いがされないこと
        expect(contractor.payments.second.paid_total_amount).to eq 0
        expect(contractor.cashback_amount).to_not eq 0

        # payment1が完済できる金額を入金
        AppropriatePaymentToInstallments.new(contractor, '20190228', 1.0, jv_user, 'hoge').call
        contractor.reload
        expect(contractor.payments.first.paid_up_ymd).to eq '20190228'

        # payment1にキャッシュバックが使用されていないこと
        expect(contractor.payments.first.paid_cashback).to eq 0

        # payment2にキャッシュバックが使用されること
        expect(contractor.payments.second.paid_cashback).to_not eq 0
      end
    end
  end

  describe 'cashback, exceeded のあまりの返却' do
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

      it '余ったキャッシュバックが戻ること' do
        AppropriatePaymentToInstallments.new(contractor, '20190228', 0, jv_user, 'hoge').call

        expect(contractor.cashback_amount).to eq 80.46
        expect(contractor.cashback_histories.use.last.cashback_amount).to eq 120
      end
    end

    context 'cashback: 0, exceeded: 200' do
      before do
        contractor.update!(pool_amount: 200)
      end

      it '余ったプール金が戻ること' do
        AppropriatePaymentToInstallments.new(contractor, '20190228', 0, jv_user, 'hoge').call

        expect(contractor.exceeded_amount).to eq 80
      end
    end

    context 'cashback: 400, exceeded: 200' do
      before do
        contractor.update!(pool_amount: 200)
        contractor.create_gain_cashback_history(400, '20190101', 0)
      end

      it '余ったキャッシュバックとプール金が戻ること' do
        AppropriatePaymentToInstallments.new(contractor, '20190228', 0, jv_user, 'hoge').call

        expect(contractor.exceeded_amount).to eq 80
        expect(contractor.cashback_amount).to eq 400.46
        expect(contractor.cashback_histories.latest.point_type).to eq 'gain'
      end
    end

    context '遅損金あり' do
      before do
        Batch::Daily.exec # 遅損金 2.66 が発生
        contractor.update!(pool_amount: 122.67)
      end

      it '余ったキャッシュバックとプール金が戻ること' do
        # 遅損金分のみを支払い
        AppropriatePaymentToInstallments.new(contractor, '20190301', 0.01, jv_user, 'hoge').call

        expect(contractor.exceeded_amount).to eq 0.02
        expect(contractor.cashback_amount).to eq 0
      end
    end
  end

  describe 'order.paid_up_ymd' do
    context '1つのpaymentに2つのorder(installment)' do
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

      it '1つのorder(installment)の支払い完了で、order.paid_up_ymdが入力されること' do
        AppropriatePaymentToInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test').call

        order1.reload
        order2.reload
        expect(order1.paid_up_ymd).to eq '20190228'
        expect(order2.paid_up_ymd).to eq nil
      end
    end

    context 'キャンセルあり' do
      let(:order1) { FactoryBot.create(:order, order_number: '1', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190101',
        canceled_at: Time.now, canceled_user: jv_user)
      }
      let(:order2) { FactoryBot.create(:order, order_number: '2', contractor: contractor,
        dealer: dealer, product: product1, installment_count: 1, purchase_ymd: '20190102',
        input_ymd: '20190116', purchase_amount: 1000.0, order_user: contractor_user)
      }

      before do
        payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
          total_amount: 1000.0, status: 'next_due')

        FactoryBot.create(:installment, order: order1, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0,
          deleted: true)

        FactoryBot.create(:installment, order: order2, payment: payment,
          installment_number: 1, due_ymd: '20190228', principal: 1000.0)
      end

      it 'キャンセルしたOrderが対象にならないこと' do
        AppropriatePaymentToInstallments.new(contractor, '20190228', 2000.0, jv_user, 'test').call

        order1.reload
        order2.reload
        expect(order1.paid_up_ymd).to eq nil
        expect(order2.paid_up_ymd).to eq '20190228'
      end
    end
  end

  describe 'payment' do
    context '1つのpaymentに1つのorder(installment)' do
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

      it 'order(installment)の支払い完了で、paymentが支払い済みになること' do
        AppropriatePaymentToInstallments.new(contractor, '20190227', 1000.0, jv_user, 'test').call

        payment.reload
        expect(payment.status).to eq 'paid'
        expect(payment.paid_up_ymd).to eq '20190227'
        expect(payment.paid_up_operated_ymd).to eq '20190228'
      end
    end

    context '1つのpaymentに2つのorder(installment)' do
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

      it '1つのorder(installment)の支払い完了で、order.paid_up_ymdが入力されること' do
        AppropriatePaymentToInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test').call

        payment.reload
        expect(payment.status).to eq 'next_due'
        expect(payment.paid_up_ymd).to eq nil
        expect(payment.paid_up_operated_ymd).to eq nil
      end
    end
  end

  describe 'installment.paid_up_ymd' do
    context '2つのorderを別の日に完済' do
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

      it 'paid_up_ymdが上書きされないこと' do
        installment1 = Order.find_by(order_number: 1).installments.first
        installment2 = Order.find_by(order_number: 2).installments.first

        expect(installment1.paid_up_ymd).to eq '20190227'
        AppropriatePaymentToInstallments.new(contractor, '20190228', 1000.0, jv_user, 'test').call
        expect(installment1.reload.paid_up_ymd).to eq '20190227'
        expect(installment2.reload.paid_up_ymd).to eq '20190228'
      end
    end
  end

  describe '遅損金が発生し、過去の日付を指定した場合にcashbackが正しく算出されること' do
    before do
      BusinessDay.update!(business_ymd: '20190216')

      order = FactoryBot.create(:order, order_number: '1', contractor: contractor,
        product: product1, installment_count: 1, purchase_ymd: '20190101',
        input_ymd: '20190115', purchase_amount: 1000.0, order_user: contractor_user)

      payment = Payment.create!(contractor: contractor, due_ymd: '20190215', total_amount: 1000.0,
        status: 'over_due')

      FactoryBot.create(:installment, order: order, payment: payment,
          installment_number: 1, due_ymd: '20190215', principal: 1000, interest: 0)

      # contractor.create_gain_cashback_history(1016.25, '20190214', 0)
      FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor,
        cashback_amount: 1016.25, total: 1016.25, exec_ymd: '20190214',
        created_at: '2019-01-01 00:00:00')
    end

    it '遅延する前の日付を指定して、遅延金分のexceededが発生しないこと' do
      AppropriatePaymentToInstallments.new(contractor, '20190215', 0, jv_user, 'test').call
      contractor.reload

      # 上の支払いで得たキャッシュバック
      latest_gain = contractor.cashback_histories.gain_latest
      expect(latest_gain.exec_ymd).to eq '20190215'

      # 消し込みの際に遅損金の分のキャッシュバックが使用されていないこと
      pre_cashback = (contractor.cashback_amount - latest_gain.cashback_amount).to_f
      expect(pre_cashback).to eq 16.25
    end
  end

  describe '免除' do
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

    it '免除なし' do
      payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      payment_total_without_late_charge =
                      contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

      # 遅損金の確認
      expect(payment_total - late_charge).to eq payment_total_without_late_charge
      expect(contractor.calc_over_due_amount).to_not eq 0

      is_exemption_late_charge = false
      AppropriatePaymentToInstallments.new(contractor, '20190316', payment_total,
        jv_user, 'test', is_exemption_late_charge).call
      contractor.reload

      expect(contractor.payments.all?(&:paid?)).to eq true
      expect(contractor.calc_over_due_amount).to eq 0
      # Receive History
      expect(contractor.receive_amount_histories.first.exemption_late_charge.to_f).to eq 0
      # Exemption late charges
      expect(Installment.all.all?{|ins| ins.exemption_late_charges.count == 0}).to eq true

      expect(contractor.exemption_late_charge_count).to eq 0

      expect(ReceiveAmountHistory.all.last.exemption_late_charge).to eq nil
    end

    it '遅損金を免除して消し込み' do
      payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      payment_total_without_late_charge =
                      contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}

      # 遅損金の確認
      expect(payment_total - late_charge).to eq payment_total_without_late_charge
      expect(contractor.calc_over_due_amount).to_not eq 0

      is_exemption_late_charge = true
      AppropriatePaymentToInstallments.new(contractor, '20190316', payment_total_without_late_charge,
        jv_user, 'test', is_exemption_late_charge).call
      contractor.reload

      expect(contractor.payments.all?(&:paid?)).to eq true
      expect(contractor.calc_over_due_amount).to eq 0
      # Receive History
      expect(contractor.receive_amount_histories.first.exemption_late_charge.to_f).to eq late_charge
      # Exemption late charges
      expect(Installment.find_by(interest: 0).exemption_late_charges.first.amount).to be > 0
      expect(Installment.find_by(interest: 25.1, due_ymd: '20190215').exemption_late_charges.first.amount).to be > 0
      expect(Installment.find_by(interest: 25.1, due_ymd: '20190315').exemption_late_charges.first.amount).to be > 0

      expect(contractor.exemption_late_charge_count).to eq 1

      expect(ReceiveAmountHistory.all.last.exemption_late_charge).to be > 0
    end

    context 'キャッシュバックあり' do
      it 'ぴったりのキャッシュバックで返済' do
        FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 3050.2)

        # 2つの遅延Paymentをキャッシュバックのみで返済
        is_exemption_late_charge = true
        AppropriatePaymentToInstallments.new(contractor, '20190316', 0, jv_user, 'test',
          is_exemption_late_charge).call
        contractor.reload

        # 遅損金を含まないキャッシュバック金額のみで返済できていること
        expect(Installment.find_by(due_ymd: '20190215', interest: 0).paid_up_ymd).to eq    '20190316'
        expect(Installment.find_by(due_ymd: '20190215', interest: 25.1).paid_up_ymd).to eq '20190316'
        expect(Installment.find_by(due_ymd: '20190315', interest: 25.1).paid_up_ymd).to eq '20190316'
        expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_up_ymd).to eq nil
        expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_total_amount).to eq 0

        # キャッシュバックが正しく使用されていること
        expect(contractor.cashback_histories.last.point_type).to eq "use"
        expect(contractor.cashback_histories.last.cashback_amount).to eq 3050.2
        expect(contractor.cashback_histories.last.total).to eq 0

        # poolが発生していないこと
        expect(contractor.pool_amount).to eq 0
      end

      it '多めのキャッシュバックで返済' do
        FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 5075.3)

        # 2つの遅延Paymentをキャッシュバックのみで返済
        is_exemption_late_charge = true
        AppropriatePaymentToInstallments.new(contractor, '20190316', 0, jv_user, 'test',
          is_exemption_late_charge).call
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

    it 'キャッシュバックがつかないこと' do
      AppropriatePaymentToInstallments.new(contractor, '20190315', 1150.0, jv_user, 'test').call
      contractor.reload

      expect(contractor.payments.first.paid?).to eq true

      expect(contractor.cashback_amount).to eq 0.0
    end
  end

  describe 'late_charge_start_ymd' do
    context '過去に元本の消し込み なし' do
      before do
        order1 = FactoryBot.create(:order, contractor: contractor,
          input_ymd: '20190115', purchase_amount: 1024.6)

        payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'next_due', total_amount: 1024.6)

        FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215',
          principal: 1000.0, interest: 24.6)
      end

      context '元本の消し込み なし' do
        it 'late_charge_start_ymdが入らないこと' do
          AppropriatePaymentToInstallments.new(contractor, '20190215', 24.6, jv_user, 'test').call
          contractor.reload

          installment = Installment.first
          installment_history = installment.target_installment_history('20190215')
          expect(installment_history.late_charge_start_ymd).to eq nil
        end
      end

      context '元本の消し込み あり' do
        it 'late_charge_start_ymdが入ること' do
          AppropriatePaymentToInstallments.new(contractor, '20190215', 1024.6, jv_user, 'test').call
          contractor.reload

          installment = Installment.first
          installment_history = installment.target_installment_history('20190215')
          expect(installment_history.late_charge_start_ymd).to eq '20190216'
        end
      end
    end

    context '過去に元本の消し込み あり' do
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

      context '元本の消し込み なし' do
        context 'over_due' do
          before do
            Payment.first.update!(status: :over_due)
            BusinessDay.update!(business_ymd: '20190216')
          end

          it '１つ前のhistoryのlate_charge_start_ymdが新しい方に移ること' do
            late_charge = contractor.orders.first.calc_remaining_late_charge
            expect(late_charge).to_not eq 0

            # 遅損金のみを支払い
            AppropriatePaymentToInstallments.new(contractor, '20190216', late_charge, jv_user, 'test').call
            contractor.reload

            installment = Installment.first
            installment_history = installment.target_installment_history('20190216')
            expect(installment_history.late_charge_start_ymd).to eq '20190202'
            expect(installment.paid_total_amount).to eq 924.6 + late_charge
          end
        end
      end

      context '元本の消し込み あり' do
        it 'late_charge_start_ymdが新たに入ること' do
          AppropriatePaymentToInstallments.new(contractor, '20190215', 100, jv_user, 'test').call
          contractor.reload

          installment = Installment.first
          installment_history = installment.target_installment_history('20190215')
          expect(installment_history.late_charge_start_ymd).to eq '20190216'

          expect(installment.paid_total_amount).to eq 1024.6
        end
      end
    end
  end

  describe 'Siteオーダーの元本支払い時のSite Credit Limitの更新' do
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

      it '元本返済なしで、Site Credit Limitが更新されないこと' do
        AppropriatePaymentToInstallments.new(contractor, '20190215', 100, jv_user, 'test').call
        site.reload

        expect(site.site_credit_limit).to eq 1000
      end

      it '元本返済ありで、Site Credit Limitが更新されること' do
        expect(site.site_credit_limit).to eq 1000
        expect(site.available_balance).to eq 0
        expect(contractor.available_balance).to eq 0

        AppropriatePaymentToInstallments.new(contractor, '20190215', 300, jv_user, 'test').call
        site.reload
        contractor.reload
        
        expect(site.site_credit_limit).to eq 800
        expect(site.available_balance).to eq 0
        expect(contractor.available_balance).to eq 200
      end
    end


    describe 'Limit以上の購入の元本返済時' do
      let(:site) { FactoryBot.create(:site, contractor: contractor, site_credit_limit: 1000) }

      before do
        order = FactoryBot.create(:order, contractor: contractor, site: site,
          input_ymd: '20190115', purchase_amount: 1050)

        payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
          status: 'next_due', total_amount: 1050)

        FactoryBot.create(:installment, order: order, payment: payment, due_ymd: '20190215',
          principal: 1050.0, interest: 0)
      end

      it 'Site Credit Limitがマイナスにならないこと' do
        AppropriatePaymentToInstallments.new(contractor, '20190215', 1040, jv_user, 'test').call
        site.reload
        contractor.reload

        expect(site.site_credit_limit).to eq 0
        expect(site.available_balance).to eq 0
        expect(contractor.available_balance).to eq 1000
      end
    end
  end

  describe '再約定したオーダーの完済' do
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

    it 'エラーにならないこと' do
      AppropriatePaymentToInstallments.new(contractor, '20190228', 1000, jv_user, 'hoge').call

      # Order
      order = contractor.orders.first
      expect(order.paid_up_ymd).to eq '20190228'
    end
  end

  describe '入金証跡の検証(ReceiveAmountDetail)' do
    before do
      BusinessDay.update!(business_ymd: '20210415')
    end

    describe '基本データの検証' do
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

      it '値が正しく登録されること' do
        AppropriatePaymentToInstallments.new(contractor, '20210415', 2500, jv_user, 'test').call

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

      context '入金が0で消し込み・免除なし' do
        it 'レコードが作成されないこと' do
          AppropriatePaymentToInstallments.new(contractor, '20210415', 0, jv_user, 'test').call

          expect(ReceiveAmountDetail.all.count).to eq 0
        end
      end
    end

    describe '消し込みがは発生しないパターン' do
      it '対象がなく、レコードが作成されないこと' do
        AppropriatePaymentToInstallments.new(contractor, '20210415', 0, jv_user, 'test').call

        expect(ReceiveAmountDetail.all.count).to eq 0
      end
    end

    describe '資料パターン' do
      # 1Order完済、1Order一部入金/1Order is paid up, 1 order is partially paid
      describe 'パターン１' do
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

        it 'データが正しく作成されること' do
          AppropriatePaymentToInstallments.new(contractor, '20210415', 2500, jv_user, 'test').call

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

      # Exceeded Occurred, Exceeded Occurred Date列はそのExceededが発生した回の入金で消込まれたOrderの中で、消込順で最後のOrderの行に入れる
      describe 'パターン４' do
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

        it 'データが正しく作成されること' do
          AppropriatePaymentToInstallments.new(contractor, '20210415', 7200, jv_user, 'test').call

          expect(ReceiveAmountDetail.all.count).to eq 2

          receive_amount_detail1 = ReceiveAmountDetail.first
          receive_amount_detail2 = ReceiveAmountDetail.last

          expect(receive_amount_detail1.switched_date).to eq '2021-03-12 01:23:45'
          expect(receive_amount_detail2.switched_date).to eq nil

          expect(receive_amount_detail1.exceeded_occurred_amount).to eq 0
          expect(receive_amount_detail1.exceeded_occurred_ymd).to eq nil
          expect(receive_amount_detail2.exceeded_occurred_amount).to eq 1000
          expect(receive_amount_detail2.exceeded_occurred_ymd).to eq '20210415'
        end
      end

      # Exceededから一部入金。DealayPenalty免除
      describe 'パターン５' do
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

        it 'データが正しく作成されること' do
          BusinessDay.update!(business_ymd: '20210501')

          AppropriatePaymentToInstallments.new(
            contractor, '20210501', 0, jv_user, 'test', true).call

          expect(ReceiveAmountDetail.all.count).to eq 1

          receive_amount_detail1 = ReceiveAmountDetail.first

          expect(receive_amount_detail1.exceeded_paid_amount).to eq 1000
          expect(receive_amount_detail1.cashback_paid_amount).to eq 0

          expect(receive_amount_detail1.waive_late_charge).to_not eq 0
        end
      end

      # "Orderが無いときに入金され、Exceededに入ったときはOrder関連項目は空欄の行を追加
      describe 'パターン６' do
        it 'データが正しく作成されること' do
          BusinessDay.update!(business_ymd: '20210501')
          AppropriatePaymentToInstallments.new(contractor, '20210501', 100, jv_user, 'test').call

          expect(ReceiveAmountDetail.all.count).to eq 1

          receive_amount_detail1 = ReceiveAmountDetail.first

          expect(receive_amount_detail1.tax_id).to eq contractor.tax_id
          expect(receive_amount_detail1.repayment_ymd).to eq '20210501'

          expect(receive_amount_detail1.principal).to eq nil
          expect(receive_amount_detail1.paid_principal).to eq nil

          expect(receive_amount_detail1.exceeded_occurred_amount).to eq 100
          expect(receive_amount_detail1.exceeded_occurred_ymd).to eq '20210501'

          expect(receive_amount_detail1.exceeded_paid_amount).to eq nil

          expect(receive_amount_detail1.waive_late_charge).to eq nil
        end
      end

      # "回払いのOrderのInstallmentが3回分一気に消し込まれたとき
      describe 'パターン７' do
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

          contractor.update!(pool_amount: 1000)
        end

        it 'データが正しく作成されること' do
          BusinessDay.update!(business_ymd: '20210715')
          AppropriatePaymentToInstallments.new(
            contractor, '20210715', 3300, jv_user, 'test', true).call

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

  describe 'new case' do
    describe 'use the payment_amount after pay selected installment' do
      describe 'same payment (No late charge)' do
        let(:order1) {
          FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 100.00, order_user: contractor_user)
        }

        let(:order2) {
          FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 100.00, order_user: contractor_user)
        }
    
        before do
          payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 200.00, status: 'next_due')
    
          installment1 = FactoryBot.create(:installment, order: order1, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 100.00, interest: 0.00)
          installment2 = FactoryBot.create(:installment, order: order2, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 100.00, interest: 0.00)
        end

        it 'should pay all installment after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          order2 = Order.find_by(order_number: '2')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order2.installments.find_by(due_ymd: '20190228')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190228',
            200.0,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (100.0)
  
          # # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(100.00)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 200.0
          expect(payment.paid_total_amount).to eq 100.0
          expect(payment.status).to eq 'next_due'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment1.principal).to eq 100.0
          expect(installment1.interest).to eq 0.0
          # 支払い済み
          expect(installment1.paid_principal).to eq 100.0
          expect(installment1.paid_interest).to eq 0.0
          expect(installment1.paid_late_charge).to eq 0.0

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            200.0,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 200.0
          expect(payment.paid_total_amount).to eq 200.0
          expect(payment.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190228'
          expect(installment2.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment2.principal).to eq 100.0
          expect(installment2.interest).to eq 0.0
          # 支払い済み
          expect(installment2.paid_principal).to eq 100.0
          expect(installment2.paid_interest).to eq 0.0
          expect(installment2.paid_late_charge).to eq 0.0
        end

        it 'should pay Partial after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          order2 = Order.find_by(order_number: '2')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order2.installments.find_by(due_ymd: '20190228')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190228',
            150.0,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (50.0)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(100.00)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 200.0
          expect(payment.paid_total_amount).to eq 100.0
          expect(payment.status).to eq 'next_due'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment1.principal).to eq 100.0
          expect(installment1.interest).to eq 0.0
          # 支払い済み
          expect(installment1.paid_principal).to eq 100.0
          expect(installment1.paid_interest).to eq 0.0
          expect(installment1.paid_late_charge).to eq 0.0

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            150.0,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 200.0
          expect(payment.paid_total_amount).to eq 150.0
          expect(payment.status).to eq 'next_due'

          # Installment2
          expect(installment2.due_ymd).to eq '20190228'
          expect(installment2.paid_up_ymd).to eq nil
          # 支払い予定
          expect(installment2.principal).to eq 100.0
          expect(installment2.interest).to eq 0.0
          # 支払い済み
          expect(installment2.paid_principal).to eq 50.0
          expect(installment2.paid_interest).to eq 0.0
          expect(installment2.paid_late_charge).to eq 0.0
        end

        it 'should pay all if there has surplus of remaining_input amount from selected pay first installment (the surplus add to exceeded)' do
          order1 = Order.find_by(order_number: '1')
          order2 = Order.find_by(order_number: '2')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order2.installments.find_by(due_ymd: '20190228')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190228',
            250.0,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (150.0)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(100.00)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 200.0
          expect(payment.paid_total_amount).to eq 100.0
          expect(payment.status).to eq 'next_due'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment1.principal).to eq 100.0
          expect(installment1.interest).to eq 0.0
          # 支払い済み
          expect(installment1.paid_principal).to eq 100.0
          expect(installment1.paid_interest).to eq 0.0
          expect(installment1.paid_late_charge).to eq 0.0

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            150.0,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 200.0
          expect(payment.paid_total_amount).to eq 200.0
          expect(payment.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190228'
          expect(installment2.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment2.principal).to eq 100.0
          expect(installment2.interest).to eq 0.0
          # 支払い済み
          expect(installment2.paid_principal).to eq 100.0
          expect(installment2.paid_interest).to eq 0.0
          expect(installment2.paid_late_charge).to eq 0.0
          contractor.reload
          expect(contractor.pool_amount).to eq(50.0)
        end
      end

      describe 'different payment' do
        let(:order) {
          FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product2, installment_count: 3, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
        }
    
        before do
          payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 341700.02, status: 'next_due')
          payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
            total_amount: 341699.99, status: 'not_due_yet')
          payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
            total_amount: 341699.99, status: 'not_due_yet')
    
          installment1 = FactoryBot.create(:installment, order: order, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
          installment2 = FactoryBot.create(:installment, order: order, payment: payment2,
            installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
          installment3 = FactoryBot.create(:installment, order: order, payment: payment3,
            installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
        end
  
        it 'should pay all installment after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order1.installments.find_by(due_ymd: '20190331')
          installment3 = order1.installments.find_by(due_ymd: '20190430')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190228',
            1025100.0,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (683399.98)
  
          # # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(333333.34)
          # expect(receive_amount_detail_data1[:paid_interest]).to eq(8366.68)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 341700.02
          expect(payment.paid_total_amount).to eq 341700.02
          expect(payment.status).to eq 'paid'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment1.principal).to eq 333333.34
          expect(installment1.interest).to eq 8366.68
          # 支払い済み
          expect(installment1.paid_principal).to eq 333333.34
          expect(installment1.paid_interest).to eq 8366.68
          expect(installment1.paid_late_charge).to eq 0.0

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            1025100.0,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload
          installment3.reload

          payment2 = contractor.payments.second.reload
          expect(payment2.due_ymd).to eq '20190331'
          expect(payment2.total_amount).to eq 341699.99
          expect(payment2.paid_total_amount).to eq 341699.99
          expect(payment2.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190331'
          expect(installment2.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment2.principal).to eq 333333.33
          expect(installment2.interest).to eq 8366.66
          # 支払い済み
          expect(installment2.paid_principal).to eq 333333.33
          expect(installment2.paid_interest).to eq 8366.66
          expect(installment2.paid_late_charge).to eq 0.0

          payment3 = contractor.payments.last.reload
          expect(payment3.due_ymd).to eq '20190430'
          expect(payment3.total_amount).to eq 341699.99
          expect(payment3.paid_total_amount).to eq 341699.99
          expect(payment3.status).to eq 'paid'

          # Installment3
          expect(installment3.due_ymd).to eq '20190430'
          expect(installment3.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment3.principal).to eq 333333.33
          expect(installment3.interest).to eq 8366.66
          # 支払い済み
          expect(installment3.paid_principal).to eq 333333.33
          expect(installment3.paid_interest).to eq 8366.66
          expect(installment3.paid_late_charge).to eq 0.0
        end

        it 'should pay Partial after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order1.installments.find_by(due_ymd: '20190331')
          installment3 = order1.installments.find_by(due_ymd: '20190430')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190228',
            641700.02,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (300000)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(333333.34)
          # expect(receive_amount_detail_data1[:paid_interest]).to eq(8366.68)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 341700.02
          expect(payment.paid_total_amount).to eq 341700.02
          expect(payment.status).to eq 'paid'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment1.principal).to eq 333333.34
          expect(installment1.interest).to eq 8366.68
          # 支払い済み
          expect(installment1.paid_principal).to eq 333333.34
          expect(installment1.paid_interest).to eq 8366.68
          expect(installment1.paid_late_charge).to eq 0.0

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            641700.02,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload
          installment3.reload

          payment2 = contractor.payments.second.reload
          expect(payment2.due_ymd).to eq '20190331'
          expect(payment2.total_amount).to eq 341699.99
          expect(payment2.paid_total_amount).to eq 300000.0
          expect(payment2.status).to eq 'not_due_yet'

          # Installment2
          expect(installment2.due_ymd).to eq '20190331'
          expect(installment2.paid_up_ymd).to eq nil
          # 支払い予定
          expect(installment2.principal).to eq 333333.33
          expect(installment2.interest).to eq 8366.66
          # 支払い済み
          expect(installment2.paid_principal).to eq 291633.34
          expect(installment2.paid_interest).to eq 8366.66
          expect(installment2.paid_late_charge).to eq 0.0

          payment3 = contractor.payments.last.reload
          expect(payment3.due_ymd).to eq '20190430'
          expect(payment3.total_amount).to eq 341699.99
          expect(payment3.paid_total_amount).to eq 0.0
          expect(payment3.status).to eq 'not_due_yet'

          # Installment3
          expect(installment3.due_ymd).to eq '20190430'
          expect(installment3.paid_up_ymd).to eq nil
          # 支払い予定
          expect(installment3.principal).to eq 333333.33
          expect(installment3.interest).to eq 8366.66
          # 支払い済み
          expect(installment3.paid_principal).to eq 0.0
          expect(installment3.paid_interest).to eq 0.0
          expect(installment3.paid_late_charge).to eq 0.0
        end

        it 'should pay all if there has surplus of remaining_input amount from selected pay first installment (the surplus add to exceeded)' do
          order1 = Order.find_by(order_number: '1')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order1.installments.find_by(due_ymd: '20190331')
          installment3 = order1.installments.find_by(due_ymd: '20190430')
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190228',
            1025200.0,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (683499.98)
  
          # # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(333333.34)
          # expect(receive_amount_detail_data1[:paid_interest]).to eq(8366.68)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 341700.02
          expect(payment.paid_total_amount).to eq 341700.02
          expect(payment.status).to eq 'paid'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment1.principal).to eq 333333.34
          expect(installment1.interest).to eq 8366.68
          # 支払い済み
          expect(installment1.paid_principal).to eq 333333.34
          expect(installment1.paid_interest).to eq 8366.68
          expect(installment1.paid_late_charge).to eq 0.0

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            1025200.0,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload
          installment3.reload

          payment2 = contractor.payments.second.reload
          expect(payment2.due_ymd).to eq '20190331'
          expect(payment2.total_amount).to eq 341699.99
          expect(payment2.paid_total_amount).to eq 341699.99
          expect(payment2.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190331'
          expect(installment2.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment2.principal).to eq 333333.33
          expect(installment2.interest).to eq 8366.66
          # 支払い済み
          expect(installment2.paid_principal).to eq 333333.33
          expect(installment2.paid_interest).to eq 8366.66
          expect(installment2.paid_late_charge).to eq 0.0

          payment3 = contractor.payments.last.reload
          expect(payment3.due_ymd).to eq '20190430'
          expect(payment3.total_amount).to eq 341699.99
          expect(payment3.paid_total_amount).to eq 341699.99
          expect(payment3.status).to eq 'paid'

          # Installment3
          expect(installment3.due_ymd).to eq '20190430'
          expect(installment3.paid_up_ymd).to eq '20190228'
          # 支払い予定
          expect(installment3.principal).to eq 333333.33
          expect(installment3.interest).to eq 8366.66
          # 支払い済み
          expect(installment3.paid_principal).to eq 333333.33
          expect(installment3.paid_interest).to eq 8366.66
          expect(installment3.paid_late_charge).to eq 0.0
          contractor.reload
          expect(contractor.pool_amount).to eq(100.0)
        end
      end

      describe 'same payment (With late charge)' do
        let(:order1) {
          FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 500.00, order_user: contractor_user)
        }

        let(:order2) {
          FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
            product: product1, installment_count: 1, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 500.00, order_user: contractor_user)
        }
    
        before do
          BusinessDay.update!(business_ymd: '20190309')
          payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 1000.00, status: 'over_due')
    
          installment1 = FactoryBot.create(:installment, order: order1, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 0.00)
          installment2 = FactoryBot.create(:installment, order: order2, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 500.00, interest: 0.00)
        end

        it 'should pay all installment after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          order2 = Order.find_by(order_number: '2')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order2.installments.find_by(due_ymd: '20190228')

          # 遅損金
          expect(installment1.calc_late_charge).to eq 13.06
          expect(installment2.calc_late_charge).to eq 13.06
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190309',
            1026.12,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (513.06)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.00)
          # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(13.06)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 1000.0
          # pp payment.paid_total_amount.to_s
          expect(payment.paid_total_amount.to_s).to eq "513.06"
          expect(payment.status).to eq 'over_due'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190309'
          # 支払い予定
          expect(installment1.principal).to eq 500.0
          expect(installment1.interest).to eq 0.0
          # 支払い済み
          expect(installment1.paid_principal).to eq 500.0
          expect(installment1.paid_interest).to eq 0.0
          expect(installment1.paid_late_charge).to eq 13.06

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190309',
            1026.12,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 1000.0
          expect(payment.paid_total_amount).to eq 1026.12
          expect(payment.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190228'
          expect(installment2.paid_up_ymd).to eq '20190309'
          # 支払い予定
          expect(installment2.principal).to eq 500.0
          expect(installment2.interest).to eq 0.0
          # 支払い済み
          expect(installment2.paid_principal).to eq 500.0
          expect(installment2.paid_interest).to eq 0.0
          expect(installment2.paid_late_charge).to eq 13.06
        end

        it 'should pay Partial after use remaining_input amount from selected pay first installment and paid late charge correctly' do
          order1 = Order.find_by(order_number: '1')
          order2 = Order.find_by(order_number: '2')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order2.installments.find_by(due_ymd: '20190228')

          # 遅損金
          expect(installment1.calc_late_charge).to eq 13.06
          expect(installment2.calc_late_charge).to eq 13.06
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190309',
            1000.00,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (486.94)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.00)
          # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(13.06)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 1000.0
          # pp payment.paid_total_amount.to_s
          expect(payment.paid_total_amount.to_s).to eq "513.06"
          expect(payment.status).to eq 'over_due'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190309'
          # 支払い予定
          expect(installment1.principal).to eq 500.0
          expect(installment1.interest).to eq 0.0
          # 支払い済み
          expect(installment1.paid_principal).to eq 500.0
          expect(installment1.paid_interest).to eq 0.0
          expect(installment1.paid_late_charge).to eq 13.06

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190309',
            1000.00,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 1000.0
          expect(payment.paid_total_amount).to eq 1000.0
          expect(payment.status).to eq 'over_due'

          # Installment2
          expect(installment2.due_ymd).to eq '20190228'
          expect(installment2.paid_up_ymd).to eq nil
          # 支払い予定
          expect(installment2.principal).to eq 500.00
          expect(installment2.interest).to eq 0.0
          # 支払い済み
          expect(installment2.paid_principal).to eq 473.88
          expect(installment2.paid_interest).to eq 0.0
          expect(installment2.paid_late_charge).to eq 13.06
        end

        it 'should pay all if there has surplus of remaining_input amount from selected pay first installment (the surplus add to exceeded)' do
          order1 = Order.find_by(order_number: '1')
          order2 = Order.find_by(order_number: '2')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order2.installments.find_by(due_ymd: '20190228')

          # 遅損金
          expect(installment1.calc_late_charge).to eq 13.06
          expect(installment2.calc_late_charge).to eq 13.06
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190309',
            1126.12,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (613.06)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(500.00)
          # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(13.06)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 1000.0
          # pp payment.paid_total_amount.to_s
          expect(payment.paid_total_amount.to_s).to eq "513.06"
          expect(payment.status).to eq 'over_due'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190309'
          # 支払い予定
          expect(installment1.principal).to eq 500.0
          expect(installment1.interest).to eq 0.0
          # 支払い済み
          expect(installment1.paid_principal).to eq 500.0
          expect(installment1.paid_interest).to eq 0.0
          expect(installment1.paid_late_charge).to eq 13.06

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190309',
            1126.12,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 1000.0
          expect(payment.paid_total_amount).to eq 1026.12
          expect(payment.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190228'
          expect(installment2.paid_up_ymd).to eq '20190309'
          # 支払い予定
          expect(installment2.principal).to eq 500.0
          expect(installment2.interest).to eq 0.0
          # 支払い済み
          expect(installment2.paid_principal).to eq 500.0
          expect(installment2.paid_interest).to eq 0.0
          expect(installment2.paid_late_charge).to eq 13.06
          expect(contractor.pool_amount).to eq(100.0)
        end
      end

      describe 'different payment (With late charge)' do
        let(:order) {
          FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product2, installment_count: 3, purchase_ymd: '20190101',
            input_ymd: '20190116', purchase_amount: 1000000.00, order_user: contractor_user)
        }
    
        before do
          BusinessDay.update!(business_ymd: '20190409')
          payment1 = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 341700.02, status: 'over_due')
          payment2 = Payment.create!(contractor: contractor, due_ymd: '20190331',
            total_amount: 341699.99, status: 'over_due')
          payment3 = Payment.create!(contractor: contractor, due_ymd: '20190430',
            total_amount: 341699.99, status: 'not_due_yet')
    
          installment1 = FactoryBot.create(:installment, order: order, payment: payment1,
            installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
          installment2 = FactoryBot.create(:installment, order: order, payment: payment2,
            installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)
          installment3 = FactoryBot.create(:installment, order: order, payment: payment3,
            installment_number: 3, due_ymd: '20190430', principal: 333333.33, interest: 8366.66)
        end

        it 'should pay all installment after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order1.installments.find_by(due_ymd: '20190331')
          installment3 = order1.installments.find_by(due_ymd: '20190430')

          # 遅損金
          expect(installment1.calc_late_charge).to eq 14154.8
          expect(installment2.calc_late_charge).to eq 6908.89
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190409',
            1046163.69,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (690308.87)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(333333.34)
          # expect(receive_amount_detail_data1[:paid_interest]).to eq(8366.68)
          # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(14154.8)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 341700.02
          # pp payment.paid_total_amount.to_s
          expect(payment.paid_total_amount).to eq 355854.82
          expect(payment.status).to eq 'paid'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190409'
          # 支払い予定
          expect(installment1.principal).to eq 333333.34
          expect(installment1.interest).to eq 8366.68
          # 支払い済み
          expect(installment1.paid_principal).to eq 333333.34
          expect(installment1.paid_interest).to eq 8366.68
          expect(installment1.paid_late_charge).to eq 14154.8

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190409',
            1046162.89,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload
          installment3.reload

          payment2 = contractor.payments.second.reload
          expect(payment2.due_ymd).to eq '20190331'
          expect(payment2.total_amount).to eq 341699.99
          expect(payment2.paid_total_amount).to eq 348608.88
          expect(payment2.status).to eq 'paid'

          # Installment2
          expect(installment2.due_ymd).to eq '20190331'
          expect(installment2.paid_up_ymd).to eq '20190409'
          # 支払い予定
          expect(installment2.principal).to eq 333333.33
          expect(installment2.interest).to eq 8366.66
          # 支払い済み
          expect(installment2.paid_principal).to eq 333333.33
          expect(installment2.paid_interest).to eq 8366.66
          expect(installment2.paid_late_charge).to eq 6908.89

          payment3 = contractor.payments.last.reload
          expect(payment3.due_ymd).to eq '20190430'
          expect(payment3.total_amount).to eq 341699.99
          pp payment3.paid_total_amount.to_s
          expect(payment3.paid_total_amount).to eq 341699.99
          expect(payment3.status).to eq 'paid'

          # Installment3
          expect(installment3.due_ymd).to eq '20190430'
          expect(installment3.paid_up_ymd).to eq '20190409'
          # 支払い予定
          expect(installment3.principal).to eq 333333.33
          expect(installment3.interest).to eq 8366.66
          # 支払い済み
          expect(installment3.paid_principal).to eq 333333.33
          expect(installment3.paid_interest).to eq 8366.66
          expect(installment3.paid_late_charge).to eq 0.0
          contractor.reload
        end

        it 'should pay Partial after use remaining_input amount from selected pay first installment' do
          order1 = Order.find_by(order_number: '1')
          installment1 = order1.installments.find_by(due_ymd: '20190228')
          installment2 = order1.installments.find_by(due_ymd: '20190331')
          installment3 = order1.installments.find_by(due_ymd: '20190430')

          # 遅損金
          expect(installment1.calc_late_charge).to eq 14154.8
          expect(installment2.calc_late_charge).to eq 6908.89
          result = AppropriatePaymentToSelectedInstallments.new(
            contractor,
            '20190409',
            371130.37,
            jv_user,
            'hoge',
            installment_ids: [installment1.id]
          ).call
          installment1.reload
          expect(result[:remaining_input_amount]).to eq (15275.55)
  
          # pay exceed so must have this to other loop
          # expect(result[:receive_amount_detail_data_arr].count).to eq(1)
          # receive_amount_detail_data1 = result[:receive_amount_detail_data_arr].find do |item|
          #   item[:installment_id] == installment1.id
          # end
          # expect(receive_amount_detail_data1[:installment_id]).to eq(installment1.id)
          # expect(receive_amount_detail_data1[:paid_principal]).to eq(333333.34)
          # expect(receive_amount_detail_data1[:paid_interest]).to eq(8366.68)
          # expect(receive_amount_detail_data1[:paid_late_charge]).to eq(14154.8)

          # Payment
          payment = contractor.payments.first.reload
          expect(payment.due_ymd).to eq '20190228'
          expect(payment.total_amount).to eq 341700.02
          # pp payment.paid_total_amount.to_s
          expect(payment.paid_total_amount).to eq 355854.82
          expect(payment.status).to eq 'paid'

          # Installment1
          expect(installment1.due_ymd).to eq '20190228'
          expect(installment1.paid_up_ymd).to eq '20190409'
          # 支払い予定
          expect(installment1.principal).to eq 333333.34
          expect(installment1.interest).to eq 8366.68
          # 支払い済み
          expect(installment1.paid_principal).to eq 333333.34
          expect(installment1.paid_interest).to eq 8366.68
          expect(installment1.paid_late_charge).to eq 14154.8

          AppropriatePaymentToInstallments.new(
            contractor,
            '20190409',
            371130.37,
            jv_user,
            'hoge',
            # receive_amount_detail_data_arr: result[:receive_amount_detail_data_arr],
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          installment2.reload

          payment2 = contractor.payments.second.reload
          expect(payment2.due_ymd).to eq '20190331'
          expect(payment2.total_amount).to eq 341699.99
          expect(payment2.paid_total_amount).to eq 15275.55
          expect(payment2.status).to eq 'over_due'

          # Installment2
          expect(installment2.due_ymd).to eq '20190331'
          expect(installment2.paid_up_ymd).to eq nil
          # 支払い予定
          expect(installment2.principal).to eq 333333.33
          expect(installment2.interest).to eq 8366.66
          # 支払い済み
          expect(installment2.paid_principal).to eq 0.0
          expect(installment2.paid_interest).to eq 8366.66
          expect(installment2.paid_late_charge).to eq 6908.89
        end
      end

      describe 'use exceeded' do
        before do
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

          contractor.update!(pool_amount: 240)
        end
    
        it 'should update and use exceeded correctly after paid selected installment and have exceeded left' do
          order1 = Order.find_by(order_number: '1')
          installment = order1.installments.find_by(installment_number: 1)
          result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call
  
          contractor.reload
          expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
          expect(result[:paid_total_exceeded]).to eq 120
          expect(result[:remaining_input_amount]).to eq 0

          expect(contractor.pool_amount).to eq 120
  
          order1.reload
          expect(order1.paid_up_ymd).to eq '20190228'
  
          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            0,
            jv_user,
            'hoge',
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          contractor.reload
          order2 = Order.find_by(order_number: '2')
          expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
          expect(order2.paid_up_ymd).to eq '20190228'
  
          # poolが発生していないこと
          expect(contractor.pool_amount).to eq 0
        end

        it 'should update and use exceeded correctly after paid selected installment and have exceeded left (have payment_amount and add remaining to exceeded)' do
          order1 = Order.find_by(order_number: '1')
          installment = order1.installments.find_by(installment_number: 1)
          result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 120, jv_user, 'hoge', installment_ids: [installment.id]).call
  
          contractor.reload
          expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
          expect(result[:paid_total_exceeded]).to eq 120.0
          expect(result[:remaining_input_amount]).to eq 120

          expect(contractor.pool_amount).to eq 120
  
          order1.reload
          expect(order1.paid_up_ymd).to eq '20190228'
  
          AppropriatePaymentToInstallments.new(
            contractor,
            '20190228',
            120,
            jv_user,
            'hoge',
            remaining_input_amount: result[:remaining_input_amount]
          ).call
          contractor.reload
          order2 = Order.find_by(order_number: '2')
          expect(result[:paid_exceeded_and_cashback_amount]).to eq 120
          expect(order2.paid_up_ymd).to eq '20190228'
  
          # poolが発生していないこと
          expect(contractor.pool_amount).to eq 120
        end
      end

      describe 'use and gain cashback' do
        context 'gain cashback' do
          before do
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 240.0, status: 'next_due')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
      
            FactoryBot.create(:installment, order: order2, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)

            contractor.create_gain_cashback_history(200, '20190101', 0)
          end

          it 'should gain cashback correctly' do
            order1 = Order.find_by(order_number: '1')
            installment = order1.installments.find_by(installment_number: 1)
            result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call
    
            contractor.reload
            expect(result[:paid_exceeded_and_cashback_amount]).to eq 100
            expect(result[:paid_total_cashback]).to eq 100
            expect(result[:remaining_input_amount]).to eq 0
  
            expect(contractor.pool_amount).to eq 0.0
    
            order1.reload
            expect(order1.paid_up_ymd).to eq '20190228'

            gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order1.id)
            expect(gain_cashback_history1).to be_present
            expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)

            expect(gain_cashback_history1.total).to eq(100.46)
    
            AppropriatePaymentToInstallments.new(
              contractor,
              '20190228',
              0,
              jv_user,
              'hoge',
              remaining_input_amount: result[:remaining_input_amount],
              receive_amount_history_id: result[:receive_amount_history_id],
              current_gain_cashback: result[:current_gain_cashback]
            ).call
            contractor.reload
            order2 = Order.find_by(order_number: '2')
            expect(result[:paid_exceeded_and_cashback_amount]).to eq 100
            expect(order2.paid_up_ymd).to eq '20190228'
            gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order2.id)
            expect(gain_cashback_history2).to be_present
            expect(gain_cashback_history2.cashback_amount).to eq(order1.calc_cashback_amount)

            expect(gain_cashback_history2.total).to eq(0.92)
            expect(gain_cashback_history2.latest).to eq(true)
    
            # poolが発生していないこと
            expect(contractor.pool_amount).to eq 0
          end
        end

        context 'use cashback' do
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
            contractor.create_gain_cashback_history(150, '20190101', 0)
          end
          it 'should create use cashback history that being use in paid selected installment correctly (create new use one)' do
            expect(contractor.cashback_histories.gain.count).to eq 1
            order1 = Order.find_by(order_number: '1')
            installment = order1.installments.find_by(installment_number: 1)
            result = AppropriatePaymentToSelectedInstallments.new(contractor, '20190228', 0, jv_user, 'hoge', installment_ids: [installment.id]).call
    
            contractor.reload
            expect(result[:paid_exceeded_and_cashback_amount]).to eq 100
            expect(result[:paid_total_cashback]).to eq 100
            expect(result[:remaining_input_amount]).to eq 0
  
            expect(contractor.pool_amount).to eq 0.0
    
            order1.reload
            expect(order1.paid_up_ymd).to eq '20190228'

            used_cashback_history = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 2)
            pp "::: used_cashback_history.id = #{used_cashback_history.id}"
            expect(used_cashback_history).to be_present
            expect(used_cashback_history.cashback_amount).to eq(100.00)

            expect(used_cashback_history.total).to eq(50.0)

            gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order1.id)
            expect(gain_cashback_history1).to be_present
            expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)

            expect(gain_cashback_history1.total).to eq(50.46)
            expect(contractor.cashback_histories.gain.count).to eq 2
            expect(contractor.cashback_histories.use.count).to eq 1
    
            AppropriatePaymentToInstallments.new(
              contractor,
              '20190228',
              0,
              jv_user,
              'hoge',
              remaining_input_amount: result[:remaining_input_amount],
              receive_amount_history_id: result[:receive_amount_history_id],
              current_gain_cashback: result[:current_gain_cashback]
            ).call
            contractor.reload
            used_cashback_history.reload
            order2 = Order.find_by(order_number: '2')
            # pp contractor.cashback_histories.to_a
            # pp order2
            expect(order2.paid_up_ymd).to eq nil
            # not fully paid so no gain cashback history
            # pp contractor.cashback_histories.gain
            # pp contractor.cashback_histories.use
            gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order2.id)
            expect(gain_cashback_history2).to be_nil
            latest_cashback_history = contractor.cashback_histories.latest
            pp latest_cashback_history
            pp latest_cashback_history.cashback_amount.to_s
            pp latest_cashback_history.total.to_s

            # the latest cashback not being use in this payment
            expect(latest_cashback_history.point_type).to eq('use')
            expect(latest_cashback_history.cashback_amount).to eq(50.0)
            expect(latest_cashback_history.total).to eq(0.46)
            expect(contractor.cashback_histories.gain.count).to eq 2
            expect(contractor.cashback_histories.use.count).to eq 2

            # poolが発生していないこと
            expect(contractor.pool_amount).to eq 0
          end
        end

        context 'use cashback (all in same payment)' do
          before do
            order1 = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
  
            order2 = FactoryBot.create(:order, order_number: '2', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)

            order3 = FactoryBot.create(:order, order_number: '3', contractor: contractor, dealer: dealer,
              product: product1, installment_count: 1, purchase_ymd: '20190101',
              input_ymd: '20190116', purchase_amount: 100.0, order_user: contractor_user)
      
            payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
              total_amount: 200.0, status: 'next_due')
      
            FactoryBot.create(:installment, order: order1, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
      
            FactoryBot.create(:installment, order: order2, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)

            FactoryBot.create(:installment, order: order3, payment: payment,
              installment_number: 1, due_ymd: '20190228', principal: 100.0, interest: 0)
          end

          context 'all paid' do
            before do
              contractor.create_gain_cashback_history(300, '20190101', 0)
            end
            it 'should create use cashback history that being use in paid selected installment correctly (create new use one)' do
              expect(contractor.cashback_histories.gain.count).to eq 1
              order1 = Order.find_by(order_number: '1')
              order2 = Order.find_by(order_number: '2')
              installment = order1.installments.find_by(installment_number: 1)
              installment2 = order2.installments.find_by(installment_number: 1)
              result = AppropriatePaymentToSelectedInstallments.new(
                contractor,
                '20190228',
                0,
                jv_user,
                'hoge',
                installment_ids: [installment.id, installment2.id]
              ).call
      
              contractor.reload
              expect(result[:paid_exceeded_and_cashback_amount]).to eq 200
              expect(result[:paid_total_cashback]).to eq 200
              expect(result[:remaining_input_amount]).to eq 0
    
              expect(contractor.pool_amount).to eq 0.0
              expect(contractor.cashback_histories.gain.count).to eq 3
              expect(contractor.cashback_histories.use.count).to eq 1
      
              order1.reload
              expect(order1.paid_up_ymd).to eq '20190228'
  
              used_cashback_history = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 2)
              pp "::: used_cashback_history.id = #{used_cashback_history.id}"
              expect(used_cashback_history).to be_present
              expect(used_cashback_history.cashback_amount).to eq(200.00)
  
              expect(used_cashback_history.total).to eq(100.0)
  
              gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order1.id)
              expect(gain_cashback_history1).to be_present
              expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)
  
              expect(gain_cashback_history1.total).to eq(100.46)
  
              gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order2.id)
              expect(gain_cashback_history2).to be_present
              expect(gain_cashback_history2.cashback_amount).to eq(order2.calc_cashback_amount)
  
              expect(gain_cashback_history2.total).to eq(100.92)
      
              AppropriatePaymentToInstallments.new(
                contractor,
                '20190228',
                0,
                jv_user,
                'hoge',
                remaining_input_amount: result[:remaining_input_amount],
                receive_amount_history_id: result[:receive_amount_history_id],
                current_gain_cashback: result[:current_gain_cashback]
              ).call
              contractor.reload
              order3 = Order.find_by(order_number: '3')
              expect(contractor.cashback_histories.gain.count).to eq 4
              expect(contractor.cashback_histories.use.count).to eq 2
  
              # used_cashback_history.reload
              # expect(used_cashback_history).to be_present
              # expect(used_cashback_history.cashback_amount).to eq(300.0)
  
              # expect(used_cashback_history.total).to eq(0.0)
              used_cashback_history2 = contractor.cashback_histories.use.last
              expect(used_cashback_history2.cashback_amount).to eq(100.0)
  
              expect(used_cashback_history2.total).to eq(0.92)
  
              gain_cashback_history1.reload
              expect(gain_cashback_history1).to be_present
              expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)
  
              expect(gain_cashback_history1.total).to eq(100.46)
  
              gain_cashback_history2.reload
              expect(gain_cashback_history2).to be_present
              expect(gain_cashback_history2.cashback_amount).to eq(order2.calc_cashback_amount)
  
              expect(gain_cashback_history2.total).to eq(100.92)

              gain_cashback_history3 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order3.id)
              expect(gain_cashback_history3).to be_present
              expect(gain_cashback_history3.cashback_amount).to eq(order3.calc_cashback_amount)
  
              expect(gain_cashback_history3.total).to eq(1.38)
              expect(gain_cashback_history3.latest).to eq(true)
            end
          end

          context 'partial' do
            before do
              contractor.create_gain_cashback_history(250, '20190101', 0)
            end
            it 'should create use cashback history that being use in paid selected installment correctly (create new use one)' do
              expect(contractor.cashback_histories.gain.count).to eq 1
              order1 = Order.find_by(order_number: '1')
              order2 = Order.find_by(order_number: '2')
              installment = order1.installments.find_by(installment_number: 1)
              installment2 = order2.installments.find_by(installment_number: 1)
              result = AppropriatePaymentToSelectedInstallments.new(
                contractor,
                '20190228',
                0,
                jv_user,
                'hoge',
                installment_ids: [installment.id, installment2.id]
              ).call
      
              contractor.reload
              expect(result[:paid_exceeded_and_cashback_amount]).to eq 200
              expect(result[:paid_total_cashback]).to eq 200
              expect(result[:remaining_input_amount]).to eq 0
    
              expect(contractor.pool_amount).to eq 0.0
              expect(contractor.cashback_histories.gain.count).to eq 3
              expect(contractor.cashback_histories.use.count).to eq 1
      
              order1.reload
              expect(order1.paid_up_ymd).to eq '20190228'
  
              used_cashback_history = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 2)
              pp "::: used_cashback_history.id = #{used_cashback_history.id}"
              expect(used_cashback_history).to be_present
              expect(used_cashback_history.cashback_amount).to eq(200.00)
  
              expect(used_cashback_history.total).to eq(50.0)
  
              gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order1.id)
              expect(gain_cashback_history1).to be_present
              expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)
  
              expect(gain_cashback_history1.total).to eq(50.46)
  
              gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order2.id)
              expect(gain_cashback_history2).to be_present
              expect(gain_cashback_history2.cashback_amount).to eq(order2.calc_cashback_amount)
  
              expect(gain_cashback_history2.total).to eq(50.92)
      
              AppropriatePaymentToInstallments.new(
                contractor,
                '20190228',
                0,
                jv_user,
                'hoge',
                remaining_input_amount: result[:remaining_input_amount],
                receive_amount_history_id: result[:receive_amount_history_id],
                current_gain_cashback: result[:current_gain_cashback]
              ).call
              contractor.reload
              order3 = Order.find_by(order_number: '3')
              expect(contractor.cashback_histories.gain.count).to eq 3
              expect(contractor.cashback_histories.use.count).to eq 2
  
              # used_cashback_history.reload
              # expect(used_cashback_history).to be_present
              # expect(used_cashback_history.cashback_amount).to eq(250.0)
  
              # expect(used_cashback_history.total).to eq(0.0)
              used_cashback_history2 = contractor.cashback_histories.use.last
              expect(used_cashback_history2.cashback_amount).to eq(50.0)
  
              expect(used_cashback_history2.total).to eq(0.92)
            end
          end
        end

        context 'use cashback partial (gain mutiple cashback case)' do
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

          it 'should create all cashback history that affect when paid selected installment correctly (update since the latest use history to latest history)' do
            expect(contractor.cashback_histories.gain.count).to eq 1
            order1 = Order.find_by(order_number: '1')
            order2 = Order.find_by(order_number: '2')
            installment = order1.installments.find_by(installment_number: 1)
            installment2 = order2.installments.find_by(installment_number: 1)
            result = AppropriatePaymentToSelectedInstallments.new(
              contractor,
              '20190228',
              0,
              jv_user,
              'hoge',
              installment_ids: [installment.id, installment2.id]
            ).call

            # pp "::: called_result = #{result}"
    
            contractor.reload
            expect(contractor.cashback_amount).to eq(50.92)
            expect(result[:paid_exceeded_and_cashback_amount]).to eq 200
            expect(result[:paid_total_cashback]).to eq 200
            expect(result[:remaining_input_amount]).to eq 0
            expect(result[:current_gain_cashback]).to eq 0.92
  
            expect(contractor.pool_amount).to eq 0.0
            expect(contractor.cashback_histories.gain.count).to eq 3
            expect(contractor.cashback_histories.use.count).to eq 1
    
            order1.reload
            expect(order1.paid_up_ymd).to eq '20190228'

            used_cashback_history = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 2)
            pp "::: used_cashback_history.id = #{used_cashback_history.id}"
            expect(used_cashback_history).to be_present
            expect(used_cashback_history.cashback_amount).to eq(200.00)

            expect(used_cashback_history.total).to eq(50.0)

            gain_cashback_history1 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order1.id)
            expect(gain_cashback_history1).to be_present
            expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)

            expect(gain_cashback_history1.total).to eq(50.46)

            gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order2.id)
            expect(gain_cashback_history2).to be_present
            expect(gain_cashback_history2.cashback_amount).to eq(order2.calc_cashback_amount)

            expect(gain_cashback_history2.total).to eq(50.92)
    
            AppropriatePaymentToInstallments.new(
              contractor,
              '20190228',
              0,
              jv_user,
              'hoge',
              remaining_input_amount: result[:remaining_input_amount],
              receive_amount_history_id: result[:receive_amount_history_id],
              current_gain_cashback: result[:current_gain_cashback]
            ).call
            contractor.reload
            order3 = Order.find_by(order_number: '3')
            expect(contractor.cashback_histories.gain.count).to eq 3
            expect(contractor.cashback_histories.use.count).to eq 2

            used_cashback_history2 = contractor.cashback_histories.use.last
            expect(used_cashback_history2.cashback_amount).to eq(50.0)

            expect(used_cashback_history2.total).to eq(0.92)
            # used_cashback_history.reload
            # expect(used_cashback_history).to be_present
            # expect(used_cashback_history.cashback_amount).to eq(250.92)

            # expect(used_cashback_history.total).to eq(0.0)

            # gain_cashback_history1.reload
            # expect(gain_cashback_history1).to be_present
            # expect(gain_cashback_history1.cashback_amount).to eq(order1.calc_cashback_amount)

            # expect(gain_cashback_history1.total).to eq(0.46)

            # gain_cashback_history2.reload
            # expect(gain_cashback_history2).to be_present
            # expect(gain_cashback_history2.cashback_amount).to eq(order2.calc_cashback_amount)

            # expect(gain_cashback_history2.total).to eq(0.92)
            # order2 = Order.find_by(order_number: '2')
            # # pp contractor.cashback_histories.to_a
            # # pp order2
            # expect(order2.paid_up_ymd).to eq nil
            # # not fully paid so no gain cashback history
            # # pp contractor.cashback_histories.gain
            # # pp contractor.cashback_histories.use
            # gain_cashback_history2 = contractor.cashback_histories.find_by(exec_ymd: '20190228', point_type: 1, order_id: order2.id)
            # expect(gain_cashback_history2).to be_nil
            # latest_cashback_history = contractor.cashback_histories.latest
            # pp latest_cashback_history
            # pp latest_cashback_history.cashback_amount.to_s
            # pp latest_cashback_history.total.to_s
            # expect(used_cashback_history.cashback_amount).to eq(150.00)
            # expect(used_cashback_history.total).to eq(0.0)

            # # the latest cashback not being use in this payment
            # expect(latest_cashback_history.point_type).to eq('gain')
            # expect(latest_cashback_history.cashback_amount).to eq(0.46)
            # expect(latest_cashback_history.total).to eq(0.46)
            # expect(contractor.cashback_histories.gain.count).to eq 2
            # expect(contractor.cashback_histories.use.count).to eq 1

            # # poolが発生していないこと
            # expect(contractor.pool_amount).to eq 0
          end
        end
      end

      # describe 'cashback history' do
      # end

      # describe 'exemption' do
      #   before do
      #     BusinessDay.update!(business_ymd: '20190316')
    
      #     order1 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
      #       purchase_amount: 1000.0)
      #     order2 = FactoryBot.create(:order, contractor: contractor, input_ymd: '20190115',
      #       purchase_amount: 3000.0)
    
      #     payment1 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190215',
      #       status: 'over_due', total_amount: 2025.1)
      #     payment2 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190315',
      #       status: 'over_due', total_amount: 1025.1)
      #     payment3 = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20190415',
      #       status: 'next_due', total_amount: 1025.1)
    
      #     FactoryBot.create(:installment, order: order1, payment: payment1, due_ymd: '20190215',
      #       principal: 1000.0, interest: 0)
    
      #     FactoryBot.create(:installment, order: order2, payment: payment1, due_ymd: '20190215',
      #       principal: 1000.0, interest: 25.1)
      #     FactoryBot.create(:installment, order: order2, payment: payment2, due_ymd: '20190315',
      #       principal: 1000.0, interest: 25.1)
      #     FactoryBot.create(:installment, order: order2, payment: payment3, due_ymd: '20190415',
      #       principal: 1000.0, interest: 25.1)
      #   end
    
      #   it 'No exemption' do
      #     payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      #     payment_total_without_late_charge =
      #                     contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      #     late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}
    
      #     # 遅損金の確認
      #     expect(payment_total - late_charge).to eq payment_total_without_late_charge
      #     expect(contractor.calc_over_due_amount).to_not eq 0
    
      #     order1 = Order.find_by(purchase_amount: 1000.0)
      #     order2 = Order.find_by(purchase_amount: 3000.0)
      #     installment1 = order1.installments.find_by(due_ymd: '20190215')
      #     installment2 = order2.installments.find_by(due_ymd: '20190215')
      #     installment3 = order2.installments.find_by(due_ymd: '20190315')
      #     installment4 = order2.installments.find_by(due_ymd: '20190415')
    
      #     is_exemption_late_charge = false
      #     result = AppropriatePaymentToSelectedInstallments.new(
      #       contractor,
      #       '20190316',
      #       payment_total,
      #       jv_user,
      #       'test',
      #       is_exemption_late_charge,
      #       installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      #     ).call
      #     contractor.reload
    
      #     expect(contractor.payments.all?(&:paid?)).to eq true
      #     expect(contractor.calc_over_due_amount).to eq 0
      #     # Exemption late charges
      #     expect(Installment.all.all?{|ins| ins.exemption_late_charges.count == 0}).to eq true
    
      #     expect(result[:total_exemption_late_charge]).to eq 0
      #   end
    
      #   it 'Waive and write off late loss charges' do
      #     order1 = Order.find_by(purchase_amount: 1000.0)
      #     order2 = Order.find_by(purchase_amount: 3000.0)
      #     installment1 = order1.installments.find_by(due_ymd: '20190215')
      #     installment2 = order2.installments.find_by(due_ymd: '20190215')
      #     installment3 = order2.installments.find_by(due_ymd: '20190315')
      #     installment4 = order2.installments.find_by(due_ymd: '20190415')
    
      #     payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      #     payment_total_without_late_charge =
      #                     contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      #     late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}
    
      #     # 遅損金の確認
      #     expect(payment_total - late_charge).to eq payment_total_without_late_charge
      #     expect(contractor.calc_over_due_amount).to_not eq 0
    
      #     is_exemption_late_charge = true
      #     result = AppropriatePaymentToSelectedInstallments.new(
      #       contractor,
      #       '20190316',
      #       payment_total_without_late_charge,
      #       jv_user,
      #       'test',
      #       is_exemption_late_charge,
      #       installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      #     ).call
      #     contractor.reload
    
      #     expect(contractor.payments.all?(&:paid?)).to eq true
      #     expect(contractor.calc_over_due_amount).to eq 0
      #     expect(Installment.find_by(interest: 0).exemption_late_charges.first.amount).to be > 0
      #     expect(Installment.find_by(interest: 25.1, due_ymd: '20190215').exemption_late_charges.first.amount).to be > 0
      #     expect(Installment.find_by(interest: 25.1, due_ymd: '20190315').exemption_late_charges.first.amount).to be > 0
    
      #     expect(result[:remaining_input_amount]).to eq 0.0
      #     expect(result[:total_exemption_late_charge]).to eq late_charge
      #     expect(contractor.exemption_late_charge_count).to eq 1
    
    
      #     expect(ReceiveAmountHistory.all.last.exemption_late_charge).to be > 0
      #   end
    
      #   it 'Waive and write off late loss charges (exceeded exemption_late_charge)' do
      #     order1 = Order.find_by(purchase_amount: 1000.0)
      #     order2 = Order.find_by(purchase_amount: 3000.0)
      #     installment1 = order1.installments.find_by(due_ymd: '20190215')
      #     installment2 = order2.installments.find_by(due_ymd: '20190215')
      #     installment3 = order2.installments.find_by(due_ymd: '20190315')
      #     installment4 = order2.installments.find_by(due_ymd: '20190415')
    
      #     payment_total = contractor.orders.sum{|order| order.calc_total_amount('20190316')}
      #     payment_total_without_late_charge =
      #                     contractor.orders.sum{|order| order.calc_total_amount('20190215')}
      #     late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}
    
      #     # 遅損金の確認
      #     expect(payment_total - late_charge).to eq payment_total_without_late_charge
      #     expect(contractor.calc_over_due_amount).to_not eq 0
    
      #     is_exemption_late_charge = true
      #     result = AppropriatePaymentToSelectedInstallments.new(
      #       contractor,
      #       '20190316',
      #       payment_total,
      #       jv_user,
      #       'test',
      #       is_exemption_late_charge,
      #       installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      #     ).call
      #     contractor.reload
    
      #     expect(contractor.payments.all?(&:paid?)).to eq true
      #     expect(contractor.calc_over_due_amount).to eq 0
      #     expect(Installment.find_by(interest: 0).exemption_late_charges.first.amount).to be > 0
      #     expect(Installment.find_by(interest: 25.1, due_ymd: '20190215').exemption_late_charges.first.amount).to be > 0
      #     expect(Installment.find_by(interest: 25.1, due_ymd: '20190315').exemption_late_charges.first.amount).to be > 0
    
      #     expect(result[:remaining_input_amount]).to eq late_charge
      #     expect(result[:total_exemption_late_charge]).to eq late_charge
    
      #     # ReceiveAmountHistory not create because remaining_amount > 0
      #     expect(ReceiveAmountHistory.all.last).to be_nil
      #     # exemption_late_charge_count not count if ReceiveAmountHistory not create
      #     expect(contractor.exemption_late_charge_count).to eq 0
      #   end
    
      #   context 'Cashback available' do
      #     it 'Repay with perfect cashback' do
      #       FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 3050.2)
      #       order1 = Order.find_by(purchase_amount: 1000.0)
      #       order2 = Order.find_by(purchase_amount: 3000.0)
      #       installment1 = order1.installments.find_by(due_ymd: '20190215')
      #       installment2 = order2.installments.find_by(due_ymd: '20190215')
      #       installment3 = order2.installments.find_by(due_ymd: '20190315')
      #       installment4 = order2.installments.find_by(due_ymd: '20190415')
      #       late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}
    
      #       # 2つの遅延Paymentをキャッシュバックのみで返済
      #       is_exemption_late_charge = true
      #       result = AppropriatePaymentToSelectedInstallments.new(
      #         contractor,
      #         '20190316',
      #         0,
      #         jv_user,
      #         'test',
      #         is_exemption_late_charge,
      #         installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      #       ).call
      #       contractor.reload
    
      #       # 遅損金を含まないキャッシュバック金額のみで返済できていること
      #       expect(Installment.find_by(due_ymd: '20190215', interest: 0).paid_up_ymd).to eq    '20190316'
      #       expect(Installment.find_by(due_ymd: '20190215', interest: 25.1).paid_up_ymd).to eq '20190316'
      #       expect(Installment.find_by(due_ymd: '20190315', interest: 25.1).paid_up_ymd).to eq '20190316'
      #       expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_up_ymd).to eq nil
      #       expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_total_amount).to eq 0
    
      #       # キャッシュバックが正しく使用されていること
      #       expect(result[:total_exemption_late_charge]).to eq late_charge
      #       expect(result[:paid_total_cashback]).to eq 3050.2
    
      #       # # poolが発生していないこと
      #       expect(contractor.exemption_late_charge_count).to eq 1
      
      
      #       expect(ReceiveAmountHistory.all.last.exemption_late_charge).to be > 0
      #     end
    
      #     it 'Pay back with more cashback' do
      #       FactoryBot.create(:cashback_history, :gain, :latest, contractor: contractor, cashback_amount: 5075.3)
    
      #       order1 = Order.find_by(purchase_amount: 1000.0)
      #       order2 = Order.find_by(purchase_amount: 3000.0)
      #       installment1 = order1.installments.find_by(due_ymd: '20190215')
      #       installment2 = order2.installments.find_by(due_ymd: '20190215')
      #       installment3 = order2.installments.find_by(due_ymd: '20190315')
      #       installment4 = order2.installments.find_by(due_ymd: '20190415')
      #       late_charge   = contractor.orders.sum{|order| order.calc_remaining_late_charge('20190316')}
    
      #       # 2つの遅延Paymentをキャッシュバックのみで返済
      #       is_exemption_late_charge = true
      #       result = AppropriatePaymentToSelectedInstallments.new(
      #         contractor, '20190316',
      #         0,
      #         jv_user,
      #         'test',
      #         is_exemption_late_charge,
      #         installment_ids: [installment1.id, installment2.id, installment3.id, installment4.id]
      #       ).call
      #       contractor.reload
    
      #       # 遅損金を含まないキャッシュバック金額のみで返済できていること
      #       expect(Installment.find_by(due_ymd: '20190215', interest: 0).paid_up_ymd).to eq    '20190316'
      #       expect(Installment.find_by(due_ymd: '20190215', interest: 25.1).paid_up_ymd).to eq '20190316'
      #       expect(Installment.find_by(due_ymd: '20190315', interest: 25.1).paid_up_ymd).to eq '20190316'
      #       expect(Installment.find_by(due_ymd: '20190415', interest: 25.1).paid_up_ymd).to eq '20190316'
    
      #       cashback_use_histories = contractor.cashback_histories.use
      #       expect(cashback_use_histories.count).to eq 1
    
      #       # キャッシュバックが正しく使用されていること
      #       expect(cashback_use_histories.last.cashback_amount).to eq 4075.3
      #       expect(cashback_use_histories.last.total).to eq 1000.0
    
      #       # poolが発生していないこと
      #       expect(contractor.pool_amount).to eq 0
      #     end
      #   end
      # end
    end
  end
end
