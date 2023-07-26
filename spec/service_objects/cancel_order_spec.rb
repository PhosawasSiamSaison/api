# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CancelOrder, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:jv_user) { FactoryBot.create(:jv_user) }

  before do
    FactoryBot.create(:business_day, business_ymd: '20201001')
  end

  describe 'payment.statusの更新' do
    let(:order) { FactoryBot.create(:order) }

    it 'ステータスが正常に更新されること' do
      expect(order.uniq_check_flg).to eq true

      CancelOrder.new(order.id, jv_user).call
      order.reload

      expect(order.canceled?).to eq true
      expect(order.uniq_check_flg).to eq nil
    end
  end

  describe 'payment.statusの更新' do
    let(:order1) { FactoryBot.create(:order, contractor: contractor) }
    let(:payment) { FactoryBot.create(:payment, :next_due, total_amount: 300) }

    before do
      FactoryBot.create(:installment, order: order1, payment: payment, principal: 100)

      # 支払い済みにするオーダー
      order2 = FactoryBot.create(:order, :inputed_date, contractor: contractor)
      FactoryBot.create(:installment, order: order2, payment: payment, paid_up_ymd: '20201001',
        principal: 300)
    end

    it '支払い済みのinstallmentがある場合に、他のinstallmentをcancelした場合にpayment.statusがpaidになること' do
      result = CancelOrder.new(order1.id, jv_user).call

      expect(result[:success]).to eq true
      expect(payment.reload.status).to eq 'paid'
    end
  end

  describe 'RUDY API' do
    let(:order) { FactoryBot.create(:order, contractor: contractor, order_number: "500") }

    it 'APIエラーならロールバックすること' do
      result = CancelOrder.new(order.id, jv_user).call

      expect(result[:success]).to eq false
      expect(result[:error]).to eq "RUDY ERROR: RUDY API ERROR"
      expect(order.reload.canceled?).to eq false
    end
  end
end
