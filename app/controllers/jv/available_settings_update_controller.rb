# frozen_string_literal: true

class Jv::AvailableSettingsUpdateController < ApplicationController
  include AvailableSettingsFormatterModule
  before_action :auth_user

  def contractor
    contractor = Contractor.find(params[:contractor_id])

    view_formatter = ViewFormatter::ContractorFormatter.new(contractor)
    formatted_contractor = view_formatter.format_update_with_hash(
      { contractor_type_label: contractor.contractor_type_label[:label] }
    )

    render json: {
      success: true,
      available_settings: format_available_settings(contractor),
      contractor: formatted_contractor,
    }
  end

  def update_available_settings
    contractor = Contractor.find(params[:contractor_id])

    ActiveRecord::Base.transaction do
      # Contractor属性の更新
      contractor.update!({
        is_switch_unavailable: params[:contractor][:is_switch_unavailable],
        update_user: login_user,
      })

      # 購入・変更可能な商品の更新
      contractor.update_available_products(params[:available_settings])
    end

    render json: { success: true }
  end
end
