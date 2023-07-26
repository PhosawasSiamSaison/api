# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdjustPaidOfInstallment, type: :model do
  describe '#call' do
    let(:contractor) { FactoryBot.create(:contractor, pool_amount: 0) }
    let(:jv_user) { FactoryBot.create(:jv_user) }
    let(:product4) { Product.find_by(product_key: 4) }

    let(:order1) {
      FactoryBot.create(:order, contractor: contractor,  product: product4, input_ymd: '20210515',
        purchase_amount: 100, paid_up_ymd: '20210716')
    }

    let(:order2) {
      FactoryBot.create(:order, contractor: contractor,  product: product4, input_ymd: '20210515',
        purchase_amount: 50)
    }

    let(:installment1) { FactoryBot.create(:installment, order: order1, payment: payment,
      paid_up_ymd: '20210716',
      paid_principal: 100, paid_interest: 2.46, paid_late_charge: 3.28,
      used_exceeded: 3.0, used_cashback: 0.28) }

    let(:payment) { FactoryBot.create(:payment, :over_due, due_ymd: '20210715',
      total_amount: 153.69, paid_total_amount: 118.61,
      paid_exceeded: 4.0, paid_cashback: 0.92)}

    let(:installment2) {
       FactoryBot.create(:installment, order: order2, payment: payment,
        paid_principal: 10, paid_interest: 1.23, paid_late_charge: 1.64,
        used_exceeded: 1.0, used_cashback: 0.64)
    }

    before do
      # installmentのprincipal, interest, late_chargeがExceededに移動すること
      # paymentのpaid_cashback, paid_exceeded, total_amountが減算されること(支払い済みのinstallmentが他にある)
      # 入金前の遅損金と同じになること(installment1と2で確認)
      # 免除のレコードが削除されていること

      FactoryBot.create(:business_day, business_ymd: '20210616')
    end

    it '正しいこと' do
      AdjustPaidOfInstallment.new.call(installment2, jv_user)

      # installment1のみの金額であること
      expect(payment.paid_total_amount).to eq (100 + 2.46 + 3.28).round(2)
      expect(payment.paid_exceeded).to eq 3
      expect(payment.paid_cashback).to eq 0.28

      # installmentの金額がリセットされること
      expect(installment2.paid_principal).to eq 0
      expect(installment2.paid_interest).to eq 0
      expect(installment2.paid_late_charge).to eq 0
      expect(installment2.used_exceeded).to eq 0
      expect(installment2.used_cashback).to eq 0

      # installment_historyがリセットされること
      expect(installment2.installment_histories.count).to eq 1
      expect(installment2.installment_histories.first.to_ymd).to eq '99991231'
    end

    it '履歴が作成されること' do
      AdjustPaidOfInstallment.new.call(installment2, jv_user)

      adjust_repayment_histories = installment2.adjust_repayment_histories
      expect(adjust_repayment_histories.count).to eq 1
      adjust_repayment_history = adjust_repayment_histories.first
      expect(adjust_repayment_history.created_user).to eq jv_user
      expect(adjust_repayment_history.business_ymd).to eq BusinessDay.today_ymd
      expect(adjust_repayment_history.to_exceeded_amount).to eq (10 + 1.23 + 1.64).round(2)
      expect(adjust_repayment_history.before_detail_json.present?).to eq true

      before_detail = JSON.parse(adjust_repayment_history.before_detail_json)
      expect(before_detail['pool_amount']).to eq 0
      expect(before_detail['payment']['paid_exceeded']).to eq 4
      expect(before_detail['payment']['paid_cashback']).to eq 0.92
      expect(before_detail['payment']['paid_total_amount']).to eq 118.61

      expect(before_detail['installment']['paid_principal']).to eq 10
      expect(before_detail['installment']['paid_interest']).to eq 1.23
      expect(before_detail['installment']['paid_late_charge']).to eq 1.64
      expect(before_detail['installment']['used_exceeded']).to eq 1
      expect(before_detail['installment']['used_cashback']).to eq 0.64
    end

    context '遅損金免除の記録あり' do
      before do
        FactoryBot.create(:exemption_late_charge, installment: installment2)
      end

      it '免除記録が削除されること' do
        AdjustPaidOfInstallment.new.call(installment2, jv_user)

        # 免除記録が削除されること
        expect(installment2.exist_exemption_late_charge).to eq false
      end
    end

    xdescribe '遅損金の確認' do
      context 'installment1のみ支払済' do
        let(:payment) { FactoryBot.create(:payment, :over_due, due_ymd: '20210715',
          total_amount: 153.69, paid_total_amount: 105.74,
          paid_exceeded: 3.0, paid_cashback: 0.28)
        }

        let(:installment2) {
           FactoryBot.create(:installment, order: order2, payment: payment,
            paid_principal: 0, paid_interest: 0, paid_late_charge: 0,
            used_exceeded: 0, used_cashback: 0)
        }

        it '' do
          expect(installment2.calc_lata_charge('20210716')).to eq 1.64
        end
      end
    end

    context '既存データのinstallment' do
      before do
        # 既存データのカラムはnilの想定
        installment2.update!(used_exceeded: nil)
      end

      it 'エラーが返ること' do
        lock_version = installment2.lock_version

        errors = AdjustPaidOfInstallment.new.call(installment2, jv_user)

        expect(errors.present?).to eq true

        # 更新されていないこと
        expect(installment2.lock_version).to eq lock_version
      end
    end

    context '完済したinstallment' do
      before do
        installment2.update!(paid_up_ymd: '20210516')
      end

      it 'エラーが返ること' do
        expect {
          AdjustPaidOfInstallment.new.call(installment2, jv_user)
        }.to raise_error(ActiveRecord::StaleObjectError)
      end
    end

    context 'Siteオーダー' do
      let(:site) { FactoryBot.create(:site, site_credit_limit: 200)}

      before do
        order2.update!(site: site)
        installment2.update!(reduced_site_limit: 100)
      end

      it 'reduced_site_limitの金額がSiteLimiに追加されること' do
        AdjustPaidOfInstallment.new.call(installment2, jv_user)

        expect(installment2.paid_total_amount).to eq 0
        expect(installment2.reduced_site_limit).to eq 0
        expect(site.site_credit_limit).to eq 300
      end
    end
  end
end
