# frozen_string_literal: true
# == Schema Information
#
# Table name: products
#
#  id                      :bigint(8)        not null, primary key
#  product_key             :integer
#  product_name            :string(40)
#  switch_sms_product_name :string(255)
#  number_of_installments  :integer
#  sort_number             :integer
#  annual_interest_rate    :decimal(5, 2)
#  monthly_interest_rate   :decimal(5, 2)
#  deleted                 :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  operation_updated_at    :datetime
#  lock_version            :integer          default(0)
#

require 'rails_helper'

RSpec.describe Product, type: :model do
  describe '#installment_amounts' do
    let(:product) { Product.find_by(product_key: 2) }
    let(:initial_amount) { 10.0 }
    let(:to_amount) { 100.0 }

    it '元本の算出処理でエラーにならないこと' do
      # フラグ
      success = true

      amount = initial_amount
      while amount <= to_amount
        break unless success

        installment_amounts = product.installment_amounts(amount.round(2))
        installments =      installment_amounts[:installments]
        total_installment = installment_amounts[:total_installment]

        # 分割した元本を合計する
        total_principal = installments.values.inject(0) {|sum, h| h[:principal] + sum}.round(2)

        # 分割の合計額と、分割前の合計額が一致するかを検証
        if total_principal != total_installment[:principal]
          p "installments: #{installments}, total_installment: #{total_installment}"
          success = false
        end

        amount += 0.01
      end

      expect(success).to eq true
    end

    it '利息の算出処理でエラーにならないこと' do
      # フラグ
      success = true

      amount = initial_amount
      while amount <= to_amount
        break unless success

        installment_amounts = product.installment_amounts(amount.round(2))
        installments =      installment_amounts[:installments]
        total_installment = installment_amounts[:total_installment]

        # 分割した利息を合計する
        total_interest = installments.values.inject(0) {|sum, h| h[:interest] + sum}.round(2)

        # 分割の合計額と、分割前の合計額が一致するかを検証
        if total_interest != total_installment[:interest]
          p "installments: #{installments}, total_installment: #{total_installment}"
          success = false
        end

        amount += 0.01
      end

      expect(success).to eq true
    end
  end

  describe '#calc_due_ymds' do
    let(:product1) { Product.find_by(product_key: 1) }
    let(:product2) { Product.find_by(product_key: 2) }
    let(:product3) { Product.find_by(product_key: 3) }
    let(:product4) { Product.find_by(product_key: 4) }
    let(:product8) { Product.find_by(product_key: 8) }

    before do
      FactoryBot.create(:system_setting)
    end

    it '分割回数が正しいこと' do
      expect(product1.calc_due_ymds('20180101').count).to eq 1

      expect(product2.calc_due_ymds('20180101').count).to eq 3

      expect(product3.calc_due_ymds('20180101').count).to eq 6

      expect(product4.calc_due_ymds('20180101').count).to eq 1
    end

    it '15日の商品の約定日が正しく算出されること' do
      expect(product8.calc_due_ymds('20220101')[1]).to eq '20220131'
      expect(product8.calc_due_ymds('20220115')[1]).to eq '20220131'
      expect(product8.calc_due_ymds('20220116')[1]).to eq '20220215'
      expect(product8.calc_due_ymds('20220131')[1]).to eq '20220215'
    end

    it '締め日が15日で適用されること' do
      calc_due_ymds = product2.calc_due_ymds('20180101')
      expect(calc_due_ymds[1]).to eq '20180215'
      expect(calc_due_ymds[2]).to eq '20180315'
      expect(calc_due_ymds[3]).to eq '20180415'

      calc_due_ymds = product2.calc_due_ymds('20180115')
      expect(calc_due_ymds[1]).to eq '20180215'
      expect(calc_due_ymds[2]).to eq '20180315'
      expect(calc_due_ymds[3]).to eq '20180415'
    end

    it '締め日が月末で適用されること' do
      calc_due_ymds = product2.calc_due_ymds('20180116')
      expect(calc_due_ymds[1]).to eq '20180228'
      expect(calc_due_ymds[2]).to eq '20180331'
      expect(calc_due_ymds[3]).to eq '20180430'

      calc_due_ymds = product2.calc_due_ymds('20180131')
      expect(calc_due_ymds[1]).to eq '20180228'
      expect(calc_due_ymds[2]).to eq '20180331'
      expect(calc_due_ymds[3]).to eq '20180430'
    end

    it '締め日と初回の約定日が年を跨ぐパターン' do
      calc_due_ymds = product2.calc_due_ymds('20181201')
      expect(calc_due_ymds[1]).to eq '20190115'
      expect(calc_due_ymds[2]).to eq '20190215'
      expect(calc_due_ymds[3]).to eq '20190315'
    end

    it '約定日が年を跨ぐパターン' do
      calc_due_ymds = product2.calc_due_ymds('20181101')
      expect(calc_due_ymds[1]).to eq '20181215'
      expect(calc_due_ymds[2]).to eq '20190115'
      expect(calc_due_ymds[3]).to eq '20190215'
    end

    it 'Product4の約定日が正しく算出されること' do
      # 締め日が15日
      calc_due_ymds = product4.calc_due_ymds('20180101')
      expect(calc_due_ymds[1]).to eq '20180315'

      # 締め日が月末
      calc_due_ymds = product4.calc_due_ymds('20180116')
      expect(calc_due_ymds[1]).to eq '20180331'
    end
  end

  describe 'あまり算出ロジック' do
    it '余りが正しく算出されること' do
      product = Product.find_by(product_key: 2)

      # フラグ
      success = true

      amount = 10.0
      while amount <= 100.0
        installment_amounts = product.installment_amounts(amount.round(2))
        installments = installment_amounts[:installments]
        total_installment = installment_amounts[:total_installment]
        interest = installments[product.number_of_installments][:interest]

        # 余りの追加されていない利息に0.01を足して、それに分割回数を掛けた値を算出(不正な利息額)
        invalid_total_interest = (interest + 0.01) * product.number_of_installments

        # 合計と同じ場合は無駄にあまりが発生しているので、そのパターンを発見する
        if invalid_total_interest == total_installment[:interest]
          success = false
          break
        end

        amount += 0.01
      end

      expect(success).to eq true
    end
  end

  # 最小金額は10.0で想定
  describe '最小金額の検証' do
    context '6分割' do
      let(:product) { Product.find_by(product_key: 3) }
      let(:installment_amounts) { product.installment_amounts(amount) }
      let(:installments) { installment_amounts[:installments] }
      let(:total_installment) { installment_amounts[:total_installment] }

      context 'amount: 10.0' do
        let(:amount) { 10.0 }

        it '元本の分割が正しいこと' do
          expect(installments[1][:principal]).to eq 1.7
          expect(installments[2][:principal]).to eq 1.66
          expect(installments[3][:principal]).to eq 1.66
          expect(installments[4][:principal]).to eq 1.66
          expect(installments[5][:principal]).to eq 1.66
          expect(installments[6][:principal]).to eq 1.66
        end

        it '利息の分割が正しいこと' do
          # totalは0.25
          expect(installments[1][:interest]).to eq 0.09
          expect(installments[2][:interest]).to eq 0.07
          expect(installments[3][:interest]).to eq 0.07
          expect(installments[4][:interest]).to eq 0.07
          expect(installments[5][:interest]).to eq 0.07
          expect(installments[6][:interest]).to eq 0.07
        end
      end
    end
  end

  describe '#interest' do
    let(:product2) { Product.find_by(product_key: 2) }

    it '浮動小数点の誤差が発生しないこと' do
      expect(product2.send(:interest, 1450.0)).to eq 36.4
    end
  end
end
