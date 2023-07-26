# frozen_string_literal: true
# == Schema Information
#
# Table name: installments
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  order_id             :integer          not null
#  payment_id           :integer
#  installment_number   :integer          not null
#  rescheduled          :boolean          default(FALSE), not null
#  exempt_late_charge   :boolean          default(FALSE), not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  principal            :decimal(10, 2)   default(0.0), not null
#  interest             :decimal(10, 2)   default(0.0), not null
#  paid_principal       :decimal(10, 2)   default(0.0), not null
#  paid_interest        :decimal(10, 2)   default(0.0), not null
#  paid_late_charge     :decimal(10, 2)   default(0.0), not null
#  used_exceeded        :decimal(10, 2)   default(0.0)
#  used_cashback        :decimal(10, 2)   default(0.0)
#  reduced_site_limit   :decimal(10, 2)   default(0.0)
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

require 'rails_helper'

RSpec.describe Installment, type: :model do
  before do
    FactoryBot.create(:system_setting)
  end

  describe '#calc_late_charge_days' do
    describe '起算日が1/16 約定日が2/28' do
      let(:order) { FactoryBot.build(:order, input_ymd: '20190116')}
      let(:installment) {
        FactoryBot.create(:installment, order: order,
          installment_number: 1, due_ymd: '20190228', principal: 900, interest: 100)
      }

      it '指定日が3/9 で 遅延日数が53日になること' do
        expect(installment.calc_late_charge_days('20190309')).to eq 53
      end

      it '指定日が2/28 で 遅延日数が0日になること' do
        expect(installment.calc_late_charge_days('20190228')).to eq 0
      end

      it '指定日が3/1 で 遅延日数が45日になること' do
        expect(installment.calc_late_charge_days('20190301')).to eq 45
      end
    end
  end

  describe '#calc_late_charge' do
    let(:area) { FactoryBot.create(:area) }
    let(:dealer) { FactoryBot.create(:dealer, area: area, dealer_name: 'Foo') }
    let(:contractor) { FactoryBot.create(:contractor, main_dealer: dealer) }
    let(:contractor_user) { FactoryBot.create(:contractor_user, contractor: contractor) }
    let(:product2) { Product.find_by(product_key: 2)}

    describe 'ケース②：延滞の場合I（※1回目のみ遅延）' do
      let(:order) {
        FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: product2.number_of_installments,
          purchase_ymd: '20190101', input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)
      }
      let(:payment1) {
        Payment.create!(contractor: contractor, due_ymd: '20190228', total_amount: 341700.02, status: 'over_due')
      }

      let(:installment1) {
        FactoryBot.create(:installment, order: order, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      }

      it '指定日が3/9 で 遅損金が 8931.00になること' do
        expect(installment1.calc_late_charge('20190309')).to eq 8931.0
      end
    end

    describe 'ケース③：延滞の場合II（※2回目のみ遅延）' do
      let(:order) {
        FactoryBot.create(:order, order_number: '1', contractor: contractor, dealer: dealer,
          product: product2, installment_count: product2.number_of_installments,
          purchase_ymd: '20190101', input_ymd: '20190116', purchase_amount: 1000000.0, order_user: contractor_user)
      }

      let(:payment1) {
        Payment.create!(contractor: contractor, due_ymd: '20190228', total_amount: 341700.02, status: 'paid')}
      let(:payment2) {
        Payment.create!(contractor: contractor, due_ymd: '20190331', total_amount: 341699.99, status: 'over_due')}

      let(:installment2) {
        FactoryBot.create(:installment, order: order, payment: payment2,
          installment_number: 2, due_ymd: '20190331', principal: 333333.33, interest: 8366.66)}

      before do
        FactoryBot.create(:installment, order: order, payment: payment1,
          installment_number: 1, due_ymd: '20190228', principal: 333333.34, interest: 8366.68)
      end

      it '指定日が4/9 で 遅損金が 8931.00になること' do
        expect(installment2.calc_late_charge('20190409')).to eq 6908.89
      end
    end

    describe 'ProjectのDelayPenaltyRate' do
      let(:contractor) { FactoryBot.create(:contractor) }
      let(:project_phase_site) {
        FactoryBot.create(:project_phase_site, contractor: contractor)
      }
      let(:order) {
        FactoryBot.create(:order, project_phase_site: project_phase_site, input_ymd: '20220201')
      }
      let(:payment) {
        FactoryBot.create(:payment, :over_due, due_ymd: '20220315', total_amount: 1000000)
      }
      let(:installment) {
        FactoryBot.create(:installment, order: order, due_ymd: '20220315', principal: 1000000)
      }

      it 'rateを2倍で遅損金も2倍になること' do
        project_phase_site.project.update!(delay_penalty_rate: 10)
        amount1 = installment.calc_late_charge('20220316')

        project_phase_site.project.update!(delay_penalty_rate: 20)
        amount2 = installment.calc_late_charge('20220316')

        expect(amount1 * 2).to eq amount2
      end
    end
  end

  describe 'scope: inputed_date_installments' do
    before do
      order1 = FactoryBot.create(:order, input_ymd: '20190102')
      order2 = FactoryBot.create(:order, contractor: order1.contractor)
      FactoryBot.create(:installment, order: order1)
      FactoryBot.create(:installment, order: order2)
    end

    it 'orderのinput_ymdがあるinstallmentのみが取得できること' do
      installments = Installment.inputed_date_installments
      expect(installments.count).to eq 1
      expect(installments.first.order.input_ymd.present?).to eq true
    end
  end

  describe '#remove_from_payment' do
    before do
      FactoryBot.create(:business_day, business_ymd: '20210815')
    end

    let(:contractor) { FactoryBot.create(:contractor) }
    let(:payment) { FactoryBot.create(:payment, :next_due, contractor: contractor, total_amount: 100) }
    let(:order1) { FactoryBot.create(:order, contractor: contractor) }
    let(:installment1) {
      FactoryBot.create(:installment, contractor: contractor, payment: payment, order: order1,
        principal: 100, interest: 0)
    }

    context '１つのinstallment' do
      it 'paymentが完済されずに削除されること' do
        installment1.remove_from_payment

        expect(payment.status).to_not eq "paid"
        expect(payment.deleted).to eq 1
      end
    end

    context '2つのinstallment' do
      let(:order2) { FactoryBot.create(:order, contractor: contractor) }
      let(:installment2) {
        FactoryBot.create(:installment, contractor: contractor, payment: payment, order: order2,
          principal: 200, interest: 0)
      }

      before do
        payment.update!(total_amount: 300)
      end

      describe '１つは未完済、もう１つを削除' do
        it '値が正しいこと' do
          installment1.remove_from_payment

          expect(payment.total_amount).to eq 200
          expect(payment.status).to_not eq "paid"
          expect(payment.deleted).to eq 0
        end
      end

      context 'installment1が完済' do
        let(:installment_paid_up_ymd) {'20210814'}

        before do
          installment1.order.update!(input_ymd: '20210714')
          installment1.update!(paid_up_ymd: installment_paid_up_ymd)
        end

        it '2を削除してpaymentを完済。paymentの完済日が最後に完済したinstallmentの完済日になること' do
          # 業務日とinstallment完済日は異なる日付で設定する
          expect(installment_paid_up_ymd).to_not eq BusinessDay.today_ymd

          installment2.update!(deleted: true)
          installment2.remove_from_payment

          expect(payment.total_amount).to eq 100
          expect(payment.status).to eq "paid"
          expect(payment.deleted).to eq 0
          expect(payment.paid_up_ymd).to eq installment_paid_up_ymd
        end
      end
    end
  end
end
