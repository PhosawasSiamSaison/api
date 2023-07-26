# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch::UpdateNextDueOnClosingDay do
  describe 'exec' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Dealer 1') }
    let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
    let(:product1) { Product.find_by(product_key: 1) }
    let(:product2) { Product.find_by(product_key: 2) }
    let(:product4) { Product.find_by(product_key: 4) }
    let(:product8) { Product.find_by(product_key: 8) }

    before do
      FactoryBot.create(:system_setting)
    end

    describe '約定日の更新' do
      describe '締め日が15日' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20190115')

          order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            input_ymd: nil, product: product1,
            installment_count: product1.number_of_installments,
            purchase_ymd: '20190101',
            purchase_amount: 1000.01, order_user: contractor_user)

          payment = Payment.create!(contractor: contractor, due_ymd: '20190215',
            total_amount: 1000.01, status: 'not_due_yet')

          FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
            due_ymd: '20190215', principal: 900.01, interest: 100)
        end

        it 'due_ymd が 次の締め日(2019-2-28) に更新されること' do
          expect(Payment.find_by(due_ymd: '20190215').present?).to eq true
          expect(Payment.find_by(due_ymd: '20190228').present?).to eq false

          Batch::UpdateNextDueOnClosingDay.exec

          expect(Payment.find_by(due_ymd: '20190215').present?).to eq false
          expect(Payment.find_by(due_ymd: '20190228').present?).to eq true
          expect(Payment.find_by(due_ymd: '20190228').status).to eq 'not_due_yet'
        end
      end

      describe '締め日が月末' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20190131')

          order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product1, installment_count: product1.number_of_installments,
            purchase_ymd: '20190116',
            purchase_amount: 1000.01, order_user: contractor_user)

          payment = Payment.create!(contractor: contractor, due_ymd: '20190228',
            total_amount: 1000.01, status: 'not_due_yet')

          FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
            due_ymd: '20190228', principal: 900.01, interest: 100)
        end

        it 'due_ymd が 次の締め日(2019-3-15) に更新されること' do
          expect(Payment.find_by(due_ymd: '20190228').present?).to eq true
          expect(Payment.find_by(due_ymd: '20190315').present?).to eq false

          Batch::UpdateNextDueOnClosingDay.exec

          expect(Payment.find_by(due_ymd: '20190228').present?).to eq false
          expect(Payment.find_by(due_ymd: '20190315').present?).to eq true
          expect(Payment.find_by(due_ymd: '20190315').status).to eq 'not_due_yet'
        end
      end
    end

    describe 'ステータス更新対象のPayment' do
      context '通常1回払い' do
        before do
          FactoryBot.create(:business_day, business_ymd: '20190115')

          order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product2, installment_count: product2.number_of_installments,
            purchase_ymd: '20190101', input_ymd: '20190110', input_ymd_updated_at: '2019-01-10 10:00:00',
            purchase_amount: 3000.01, order_user: contractor_user)

          payment = Payment.create!(contractor: contractor, due_ymd: '20190215',
            total_amount: 1000.01, status: 'not_due_yet')

          FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
            due_ymd: '20190215', principal: 900.01, interest: 100)
        end

        it 'sutatus が next_due に更新されること' do
          expect(Payment.find_by(due_ymd: '20190215').status).to eq 'not_due_yet'

          Batch::UpdateNextDueOnClosingDay.exec

          expect(Payment.find_by(due_ymd: '20190215').status).to eq 'next_due'

        end
      end

      describe 'スキップ1回払い' do
        before do
          order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
            product: product4, installment_count: product4.number_of_installments,
            purchase_ymd: '20190101', input_ymd: input_ymd, input_ymd_updated_at: '2019-01-10 10:00:00',
            purchase_amount: 3000.01, order_user: contractor_user)

          payment = Payment.create!(contractor: contractor, due_ymd: due_ymd,
            total_amount: 1000.01, status: 'not_due_yet')

          FactoryBot.create(:installment, order: order, payment: payment, installment_number: 1,
            due_ymd: due_ymd, principal: 900.01, interest: 100)
        end

        context 'Input Dateが締め日をまたいでいないパターン' do
          let(:input_ymd) { '20190115' }
          let(:due_ymd) { '20190315' }

          before do
            FactoryBot.create(:business_day, business_ymd: '20190215')
          end

          it 'sutatus が next_due に更新されること' do
            expect(Payment.find_by(due_ymd: due_ymd).status).to eq 'not_due_yet'
            expect(Payment.count).to eq 1

            Batch::UpdateNextDueOnClosingDay.exec

            expect(Payment.find_by(due_ymd: due_ymd).status).to eq 'next_due'
            expect(Payment.count).to eq 1
          end
        end

        context 'Input Dateが締め日をまたいでいたパターン' do
          let(:input_ymd) { '20190116' }
          let(:due_ymd) { '20190331' }

          before do
            FactoryBot.create(:business_day, business_ymd: '20190228')
          end

          it 'sutatus が next_due に更新されること' do
            expect(Payment.find_by(due_ymd: due_ymd).status).to eq 'not_due_yet'
            expect(Payment.count).to eq 1

            Batch::UpdateNextDueOnClosingDay.exec

            expect(Payment.find_by(due_ymd: due_ymd).status).to eq 'next_due'
            expect(Payment.count).to eq 1
          end
        end
      end
    end

    describe '15日商品' do
      describe 'Product1がpaidのpaymentにproduct8のInputなしがある状態' do
        let(:payment) {
          FactoryBot.create(:payment, :paid, due_ymd: '20220215', contractor: contractor,
            paid_up_ymd: '20220116', total_amount: 1000)
        }

        before do
          FactoryBot.create(:business_day, business_ymd: '20220131')

          FactoryBot.create(:installment, payment: payment, principal: 600, contractor: contractor,
            order: FactoryBot.create(:order, input_ymd: '20220115', contractor: contractor)
          )

          FactoryBot.create(:installment, payment: payment, principal: 400, contractor: contractor,
            order: FactoryBot.create(:order, product: product8, contractor: contractor)
          )
        end

        it '締め日のステータス更新でpaidのままであること' do
          Batch::UpdateNextDueOnClosingDay.exec

          payment = contractor.payments.find_by(due_ymd: '20220215')

          expect(payment.status).to eq 'paid'
        end

        it '移動したproduct8のpaymentのstatusがnot_due_yetであること' do
          Batch::UpdateNextDueOnClosingDay.exec

          payment = Payment.find_by(due_ymd: '20220228')

          expect(payment.status).to eq 'not_due_yet'
        end
      end

      describe 'InputDateあり' do
        let(:payment) {
          FactoryBot.create(:payment, :not_due_yet, due_ymd: '20220215', contractor: contractor)
        }

        before do
          FactoryBot.create(:business_day, business_ymd: '20220131')

          FactoryBot.create(:installment, payment: payment,
            order: FactoryBot.create(:order, input_ymd: '20220116')
          )
        end

        it 'not_due_yetからnext_dueに更新されること' do
          Batch::UpdateNextDueOnClosingDay.exec

          expect(payment.reload.next_due?).to eq true
        end
      end
    end

    describe 'PF' do
      let(:project_phase_site) { FactoryBot.create(:project_phase_site, contractor: contractor) }
      let(:order) { contractor.include_pf_orders.first }

      before do
        FactoryBot.create(:business_day, business_ymd: '20190115')

        order = FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          project_phase_site: project_phase_site,
          input_ymd: nil,
          product: product1,
          installment_count: product1.number_of_installments,
          purchase_ymd: '20190101',
          purchase_amount: 1000.01,
          order_user: contractor_user
        )

        FactoryBot.create(:installment, order: order, installment_number: 1,
          due_ymd: '20190215', principal: 900.01, interest: 100)
      end

      it 'PFのオーダーがエラーにならずに更新されること' do
        expect(order.installments.first.due_ymd).to eq '20190215'

        Batch::UpdateNextDueOnClosingDay.exec

        expect(order.installments.first.due_ymd).to eq '20190228'
      end
    end
  end
end
