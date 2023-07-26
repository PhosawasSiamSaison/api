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

class AvailableProduct < ApplicationRecord
  belongs_to :contractor
  belongs_to :product

  validates :contractor, uniqueness: { scope: [:category, :product, :dealer_type], case_sensitive: false }

  class << self
    # 購入・変更・キャッシュバック可能な、商品・Dealer Typeの設定リスト
    # Contractorの登録時はContractorはnilの想定
    def available_settings(contractor = nil, contractor_type = nil)
      contractor_type = contractor.present? ? contractor.contractor_type : contractor_type

      all_dealer_types = ApplicationRecord.dealer_types
      all_products = Product.all.order(:sort_number)

      available_products = contractor ? contractor.available_products : nil

      formatted_products = all_products.map do |product|
        {
          product_key: product.product_key,
          product_name: product.product_name,
        }
      end

      # 個別設定のレコードがなければグローバル設定を使う判定にする
      purchase_use_global = contractor ? !available_products.exists?(category: :purchase) : true
      switch_use_global   = contractor ? !available_products.exists?(category: :switch) : true
      cashback_use_global = contractor ? !available_products.exists?(category: :cashback) : true

      global_settings = GlobalAvailableSetting.format_global_available_settings(contractor_type)

      # Purchas
      purchase_dealer_type = {}
      all_dealer_types.keys.map {|dealer_type|
        purchase_available_products = purchase_use_global ?
          nil : available_products.where(category: :purchase, dealer_type: dealer_type)

        product_keys = {}
        all_products.each do |product|
          product_key = product.product_key
          global_available = global_settings.dig(:purchase, dealer_type.to_sym, product_key)

          if purchase_use_global
            available = global_available
            is_changed = false
          else
            purchase_available_product = purchase_available_products.find_by(product: product)

            available =
              purchase_available_product ? purchase_available_product.available : global_available

            is_changed = available != global_available
          end

          product_keys[product_key] = {
            available: available,
            global_setting: global_available,
            is_changed: is_changed,
          }
        end

        purchase_dealer_type[dealer_type.to_sym] = {
          product_key: product_keys
        }
      }

      # Switch
      switch_dealer_type = {}
      all_dealer_types.keys.map {|dealer_type|
        switch_available_products = switch_use_global ?
          nil : available_products.where(category: :switch, dealer_type: dealer_type)

        product_keys = {}

        all_products.each do |product|
          product_key = product.product_key
          global_available = global_settings.dig(:switch, dealer_type.to_sym, product_key)

          if switch_use_global
            available = global_available
            is_changed = false
          else
            switch_available_product = switch_available_products.find_by(product: product)

            available =
              switch_available_product ? switch_available_product.available : global_available

            is_changed = available != global_available
          end

          product_keys[product_key] = {
            available: available,
            global_setting: global_available,
            is_changed: is_changed,
          }
        end

        switch_dealer_type[dealer_type.to_sym] = {
          product_key: product_keys
        }
      }

      # Cashback
      cashback_product = Product.find_by(product_key: 1)
      cashback_dealer_type = {}
      all_dealer_types.keys.map {|dealer_type|
        cashback_available_products = cashback_use_global ?
          nil : available_products.where(category: :cashback, dealer_type: dealer_type)

        # キャッシュバックの商品は固定
        global_available = global_settings.dig(:cashback, dealer_type.to_sym)

        if cashback_use_global
          available = global_available
          is_changed = false
        else
          cashback_available_product = cashback_available_products.find_by(product: cashback_product)

          available =
            cashback_available_product ? cashback_available_product.available : global_available

          is_changed = available != global_available
        end

        cashback_dealer_type[dealer_type.to_sym] = {
          available: available,
          global_setting: global_available,
          is_changed: is_changed,
        }
      }

      {
        no_dealer_limit_settings: no_dealer_limit_settings(contractor),
        is_switch_unavailable: contractor ? contractor.is_switch_unavailable : false,
        purchase_use_global: purchase_use_global,
        switch_use_global:   switch_use_global,
        cashback_use_global: cashback_use_global,
        purchase: {
          products: formatted_products,
          dealer_type: purchase_dealer_type,
        },
        switch: {
          products: formatted_products,
          dealer_type: switch_dealer_type,
        },
        cashback: {
          dealer_type: cashback_dealer_type,
        }
      }
    end
  end

  private
    def self.dealer_type_label(dealer_type)
      {
        code: dealer_type,
        label: dealer_type_labels[dealer_type.to_sym],
      }
    end

    def self.no_dealer_limit_settings(contractor)
      if contractor
        # 全てのDealerで購入できる判定の場合は全てのAvailable Settingを表示する
        return false if contractor.use_only_credit_limit

        contractor.latest_dealer_limits.blank?
      else
        true
      end
    end
end
