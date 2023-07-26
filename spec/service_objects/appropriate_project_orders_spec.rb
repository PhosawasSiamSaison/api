# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AppropriateProjectOrders, type: :model do
  let(:jv_user) { FactoryBot.create(:jv_user) }
  let(:contractor) { FactoryBot.create(:contractor) }
  let(:product1) { Product.find_by(product_key: 1) }

  let(:project) { FactoryBot.create(:project) }
  let(:project_phase) { FactoryBot.create(:project_phase, project: project) }
  let(:project_phase_site) { FactoryBot.create(:project_phase_site, project_phase: project_phase,
    contractor: contractor) }
  let(:sol_dealer) { FactoryBot.create(:sol_dealer) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20220111')
  end

  describe '正常パターン' do
    let(:is_exemption_late_charge) { false }
    let(:payment_ymd) { '20220111' }
    let(:order) { FactoryBot.create(:order, contractor: contractor, dealer: sol_dealer,
      project_phase_site: project_phase_site, product: product1, purchase_ymd: '20220111',
      purchase_amount: 10700, amount_without_tax: 10000, input_ymd: '20220111') }

    before do
      FactoryBot.create(:installment, order: order, contractor: contractor,
        due_ymd: '20220215', principal: 9000, interest: 1000)
    end

    it 'エラーにならないこと' do
      AppropriateProjectOrders.new.call(project_phase_site, payment_ymd, 10000, jv_user,
        'comment', is_exemption_late_charge
      )
      order.reload

      expect(order.paid_up_ymd).to eq payment_ymd

      # 入金履歴の検証
      project_receive_amount_history = project_phase_site.project_receive_amount_histories.first

      expect(project_receive_amount_history.present?).to eq true
      expect(project_receive_amount_history.receive_amount).to eq 10000
      expect(project_receive_amount_history.receive_ymd).to eq payment_ymd
      expect(project_receive_amount_history.exemption_late_charge).to eq nil
      expect(project_receive_amount_history.comment).to eq 'comment'
      expect(project_receive_amount_history.create_user).to eq jv_user


      # project_phase_site
      expect(project_phase_site.paid_total_amount).to eq 10000
    end

    context '遅損金あり' do
      let(:payment_ymd) { '20230111' }

      before do
        BusinessDay.update!(business_ymd: '20230111')
      end

      it '遅損金のみを支払い' do
        late_charge = project_phase_site.calc_total_late_charge(payment_ymd)

        AppropriateProjectOrders.new.call(project_phase_site, payment_ymd, late_charge, jv_user,
          'comment', is_exemption_late_charge
        )
        order.reload

        expect(order.paid_up_ymd).to eq nil

        # 入金履歴の検証
        project_receive_amount_history = project_phase_site.project_receive_amount_histories.first

        expect(project_receive_amount_history.present?).to eq true
        expect(project_receive_amount_history.receive_amount).to eq late_charge
        expect(project_receive_amount_history.receive_ymd).to eq payment_ymd
        expect(project_receive_amount_history.exemption_late_charge).to eq nil
        expect(project_receive_amount_history.comment).to eq 'comment'
        expect(project_receive_amount_history.create_user).to eq jv_user


        # project_phase_site
        expect(project_phase_site.paid_total_amount).to eq late_charge
      end

      context '免除' do
        let(:is_exemption_late_charge) { true }

        it '正常に処理されること' do
          is_exemption_late_charge = true

          # 遅損金があること
          expect(project_phase_site.calc_total_late_charge(payment_ymd)).to_not eq 0

          AppropriateProjectOrders.new.call(project_phase_site, payment_ymd, 10000, jv_user,
            'comment', is_exemption_late_charge
          )
          order.reload

          # 完済できていること
          expect(order.paid_up_ymd).to eq payment_ymd

          # 遅損金がないこと
          expect(project_phase_site.calc_total_late_charge(payment_ymd)).to eq 0

          # 入金履歴の検証
          project_receive_amount_history = project_phase_site.project_receive_amount_histories.first

          expect(project_receive_amount_history.present?).to eq true
          expect(project_receive_amount_history.receive_amount).to eq 10000
          expect(project_receive_amount_history.receive_ymd).to eq payment_ymd
          expect(project_receive_amount_history.exemption_late_charge).to_not eq 0

          # project_phase_site
          expect(project_phase_site.paid_total_amount).to eq 10000
        end
      end
    end

    context 'Input Dateなしのオーダー' do
      before do
        order.update!(input_ymd: nil)

        it '消し込みがされないこと' do
          AppropriateProjectOrders.new.call(project_phase_site, payment_ymd, 10000, jv_user,
            'comment', is_exemption_late_charge
          )
          order.reload

          expect(order.paid_up_ymd).to eq nil

          expect(project_phase_site.paid_total_amount).to eq 0
          expect(project_phase_site.paid_total_amount_with_refund).to eq 10000
        end
      end
    end
  end
end
