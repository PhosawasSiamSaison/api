# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SwitchSubDealer, type: :model do
  let(:contractor) { FactoryBot.create(:contractor, :sub_dealer) }
  let(:product1) { Product.find_by(product_key: 1) }
  let(:product2) { Product.find_by(product_key: 2) }
  let(:product5) { Product.find_by(product_key: 5) }
  let(:order) { FactoryBot.create(:order, contractor: contractor, product: product1,
    input_ymd: '20210515')}
  let(:login_user) { FactoryBot.create(:jv_user) }
  let(:orders) {
    [
      { "id" => order.id, "lock_version" => order.lock_version }
    ]
  }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20210616')

    payment = FactoryBot.create(:payment, :over_due, contractor: contractor, due_ymd: '20210615')
    FactoryBot.create(:installment, payment: payment, order: order)

    FactoryBot.create(:available_product, :cbm, :switch, :available,
      contractor: contractor, product: product5)
  end

  describe '#exec_switch' do
    describe '正常値' do
      it 'Switchされること' do
        SwitchSubDealer.new.exec_switch(orders, login_user)
        order.reload

        expect(order.product.product_key).to eq product5.product_key
      end

      context 'Product5にSwitchの申請中' do
        before do
          contractor_user = FactoryBot.create(:contractor_user, contractor: contractor)

          change_product_apply =
            FactoryBot.create(:change_product_apply, contractor: contractor, due_ymd: '20210615',
              apply_user: contractor_user)

          order.update!(
            change_product_status: :applied,
            is_applying_change_product: true,
            applied_change_product: product5,
            change_product_applied_at: Time.zone.now,
            change_product_applied_user: contractor_user,
            change_product_apply: change_product_apply,
          )
        end

        it 'Switchされること' do
          expect(ChangeProductApply.count).to eq 1

          SwitchSubDealer.new.exec_switch(orders, login_user)
          order.reload

          expect(order.product.product_key).to eq product5.product_key
          expect(ChangeProductApply.count).to eq 0

          # 申請データは削除されること
          expect(order.change_product_apply).to eq nil
          expect(order.is_applying_change_product).to eq false
          expect(order.applied_change_product).to eq nil
          expect(order.change_product_applied_at).to eq nil
          expect(order.change_product_applied_user).to eq nil
          expect(order.change_product_apply).to eq nil
        end

        context 'GH Order追加、GHのSwitchはUnavailable' do
          before do
            change_product_apply = ChangeProductApply.first

            # gh orderをproduct2でswitch申請
            order = FactoryBot.create(:order, :applied_change_product, :global_house, contractor: contractor,
              input_ymd: '20210515', change_product_apply: change_product_apply)

            payment = Payment.find_by(due_ymd: '20210615')
            FactoryBot.create(:installment, order: order, payment: payment)

            FactoryBot.create(:available_product, :gh, :switch, :available, contractor: contractor,
              product: product2)
            FactoryBot.create(:available_product, :gh, :switch, :unavailable, contractor: contractor,
              product: product5)
          end

          it 'cbmのみがProduct5へSwitchされること。紐付くChangeProductApplyが削除ないこと' do
            SwitchSubDealer.new.exec_switch(orders, login_user)

            cbm_order = Order.eager_load(:dealer).where(dealers: { dealer_type: :cbm }).first
            expect(cbm_order.product.product_key).to eq 5
            payment = Payment.first
            expect(payment.due_ymd).to eq '20210715'
            expect(payment.next_due?).to eq true
            expect(cbm_order.change_product_apply).to eq nil

            change_product_apply = ChangeProductApply.first
            expect(change_product_apply.present?).to eq true
            expect(change_product_apply.orders.count).to eq 1
            expect(change_product_apply.orders.first.dealer.dealer_type).to eq 'global_house'
          end
        end
      end
    end

    describe 'Switch対象外の検証' do
      context 'product5以外にSwitchを申請中' do
        before do
          FactoryBot.create(:available_product, :cbm, :switch, :available,
            contractor: contractor, product: product2)

          contractor_user = FactoryBot.create(:contractor_user, contractor: contractor)

          change_product_apply =
            FactoryBot.create(:change_product_apply, contractor: contractor, due_ymd: '20210615',
              apply_user: contractor_user)

          order.update!(
            change_product_status: :applied,
            is_applying_change_product: true,
            applied_change_product: product2,
            change_product_applied_at: Time.zone.now,
            change_product_applied_user: contractor_user,
            change_product_apply: change_product_apply,
          )
        end

        it 'Switchされないこと' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end
    end

    context '対象外' do
      context 'not sub_dealer' do
        before do
          contractor.normal!
        end

        it 'Switchされないこと' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end

      context 'rejected' do
        before do
          Order.first.update!(
            change_product_status: :rejected,
          )
        end

        it 'エラーがraiseされること' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end

      context 'Product1以外' do
        before do
          Order.first.update!(
            product: product2,
          )
        end

        it 'エラーがraiseされること' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end

      context '一部支払いずみ' do
        before do
          Installment.first.update!(paid_principal: 1)
        end

        it 'エラーがraiseされること' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end

      context 'Switch権限なし' do
        before do
          AvailableProduct.first.update!(available: false)
        end

        it 'エラーがraiseされること' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end

      context 'Unavailable' do
        before do
          Contractor.first.update!(is_switch_unavailable: true)
        end

        it 'エラーがraiseされること' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end

      context 'Rescheduled New Order' do
        before do
          Order.first.update!(rescheduled_at: Time.now)
        end

        it 'エラーがraiseされること' do
          expect{
            SwitchSubDealer.new.exec_switch(orders, login_user)
          }.to raise_error(ActiveRecord::StaleObjectError)
        end
      end
    end
  end
end
