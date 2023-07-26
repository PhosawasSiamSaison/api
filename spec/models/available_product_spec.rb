# frozen_string_literal: true

# == Schema Information
#
# Table name: available_products
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  category             :integer          not null
#  product_id           :bigint(8)        not null
#  dealer_type          :integer          not null
#  available            :boolean          not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#


require 'rails_helper'

RSpec.describe AvailableProduct, type: :model do
  let(:contractor) { FactoryBot.create(:contractor) }

  describe 'available_settings' do
    let(:product1) { Product.find_by(product_key: 1) }
    let(:product2) { Product.find_by(product_key: 2) }
    let(:product3) { Product.find_by(product_key: 3) }
    let(:product4) { Product.find_by(product_key: 4) }
    let(:product5) { Product.find_by(product_key: 5) }

    before  do
      GlobalAvailableSetting.find_by(contractor_type: :normal, category: :purchase, dealer_type: :cbm, product: product5)
        .update!(available: false)

      # デフォルトとは異なる値を設定
      FactoryBot.create(:available_product, :purchase, :cbm, contractor: contractor,
        product: product1, available: false)

      FactoryBot.create(:available_product, :purchase, :cbm, contractor: contractor,
        product: product5, available: true)
    end

    it 'カスタム設定が正しく取得できること' do
      available_settings = AvailableProduct.available_settings(contractor)

      product_keys = available_settings[:purchase][:dealer_type][:cbm][:product_key]
      product_key1 = product_keys[1]
      product_key5 = product_keys[5]

      expect(product_key1[:available]).to eq false
      expect(product_key1[:global_setting]).to eq true
      expect(product_key1[:is_changed]).to eq true

      expect(product_key5[:available]).to eq true
      expect(product_key5[:global_setting]).to eq false
      expect(product_key5[:is_changed]).to eq true
    end

    it '設定していないDealerTypeはグローバルの値が取得できること' do
      available_settings = AvailableProduct.available_settings(contractor)

      product_keys = available_settings[:purchase][:dealer_type][:q_mix][:product_key]
      product_key1 = product_keys[1]

      expect(product_key1[:available]).to eq true
      expect(product_key1[:global_setting]).to eq true
      expect(product_key1[:is_changed]).to eq false
    end
  end
end
