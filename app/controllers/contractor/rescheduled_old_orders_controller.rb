# frozen_string_literal: true

class Contractor::RescheduledOldOrdersController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def order_list
    new_order = login_user.contractor.orders.rescheduled_new_orders.find(params[:order_id])
    old_orders = new_order.rescheduled_old_orders

    formatted_old_orders = old_orders.map do |order|
      format_contractor_order_detail(order)
    end

    render json: {
      success: true,
      orders: formatted_old_orders,
    }
  end
end
