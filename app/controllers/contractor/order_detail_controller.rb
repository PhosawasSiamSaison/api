# frozen_string_literal: true

class Contractor::OrderDetailController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def order_detail
    order = find_order

    render json: {
      success: true,
      order: format_contractor_order_detail(order)
    }
  end

  private

  def find_order
    login_user.contractor.orders.exclude_canceled.find(params[:order_id])
  end
end
