# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RegisterAppliedChangeProduct, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  before do
    FactoryBot.create(:system_setting)
    FactoryBot.create(:business_day, business_ymd: '20210228')
  end

  describe '正常' do
    before do
      change_product_apply = FactoryBot.create(:change_product_apply, contractor: contractor,
        due_ymd: '20210228')
      order = FactoryBot.create(:order, :inputed_date, :applied_change_product,
        contractor: contractor, change_product_apply: change_product_apply)
      payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20210228')
      FactoryBot.create(:installment, order: order, payment: payment)
    end

    it '正しい形式で返ること' do
      change_product_apply_id = ChangeProductApply.first.id
      orders = [
        {
          id: Order.first.id,
          change_product_status: "approval"
        }
      ]
      memo = ''
      login_user = nil

      errors, change_product_apply = RegisterAppliedChangeProduct.new(
        change_product_apply_id,
        orders,
        memo,
        login_user
      ).call

      expect(errors).to eq nil
      expect(change_product_apply.present?).to eq true
    end

    context '期限切れ' do
      before do
        BusinessDay.update!(business_ymd: '20210301')
      end

      it '承認できること' do
        change_product_apply_id = ChangeProductApply.first.id
        orders = [
          {
            id: Order.first.id,
            change_product_status: "approval"
          }
        ]
        memo = ''
        login_user = nil

        errors, change_product_apply = RegisterAppliedChangeProduct.new(
          change_product_apply_id,
          orders,
          memo,
          login_user
        ).call

        expect(errors).to eq nil
        expect(change_product_apply.present?).to eq true
      end
    end
  end

  describe 'StaleObjectエラー' do
    before do
      change_product_apply = FactoryBot.create(:change_product_apply, contractor: contractor,
        due_ymd: '20210228')

      # キャンセルにする
      order = FactoryBot.create(:order, :canceled, :inputed_date, :applied_change_product,
        contractor: contractor, change_product_apply: change_product_apply)
      payment = FactoryBot.create(:payment, contractor: contractor, due_ymd: '20210228')
      FactoryBot.create(:installment, order: order, payment: payment)
    end

    it 'エラーが正しい形式で返ること' do
      change_product_apply_id = ChangeProductApply.first.id
      orders = [
        {
          id: Order.first.id,
          change_product_status: "approval"
        }
      ]
      memo = ''
      login_user = nil

      errors, change_product_apply = RegisterAppliedChangeProduct.new(
        change_product_apply_id,
        orders,
        memo,
        login_user
      ).call

      expect(errors).to eq [I18n.t("error_message.stale_object_error")]
    end
  end
end
