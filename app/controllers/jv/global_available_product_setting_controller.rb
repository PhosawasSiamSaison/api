# frozen_string_literal: true

class Jv::GlobalAvailableProductSettingController < ApplicationController
  include AvailableSettingsFormatterModule

  before_action :auth_user

  def global_available_product_setting
    contractor_type = params[:contractor_type]

    render json: {
      success: true,
      global_available_product_settings: format_available_settings(contractor_type: contractor_type)
    }
  end

  def update_setting
    contractor_type = params[:contractor_type]
    checked_available_setting = params[:checked_available_setting]

    # 権限チェック
    errors = check_permission_errors(login_user.md?)
    return render json: { success: false, errors:  errors } if errors.present?

    ActiveRecord::Base.transaction do
      products = Product.all
      product_key1 = products.find_by(product_key: 1) # cashback更新用

      ApplicationRecord.categories.keys.each {|category|
        ApplicationRecord.dealer_types.keys.each {|dealer_type|
          if category == "cashback"
            checked_dealer_type = checked_available_setting["cashback"]

            GlobalAvailableSetting.find_by(
              contractor_type: contractor_type,
              category: category,
              dealer_type: dealer_type,
              product_id: product_key1.id
            ).update!(
              available: checked_dealer_type.include?(dealer_type)
            )
          else
            products.each {|product|
              checked_product_keys = checked_available_setting[category][dealer_type]

              GlobalAvailableSetting.find_by(
                contractor_type: contractor_type,
                category: category,
                dealer_type: dealer_type,
                product_id: product.id
              ).update!(
                available: checked_product_keys.include?(product.product_key)
              )
            }
          end
        }
      }
    end

    render json: {
      success: true
    }
  end
end
