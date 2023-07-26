# frozen_string_literal: true

class Jv::ChangeProductApplyListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    change_product_applies, total_count = ChangeProductApply.search_list(params)

    render json: {
      success: true,
      change_product_applies: change_product_applies.map {|change_product_apply|
        contractor = change_product_apply.contractor

        {
          id: change_product_apply.id,
          applied_at: change_product_apply.created_at,
          contractor: {
            tax_id:          contractor.tax_id,
            en_company_name: contractor.en_company_name,
            th_company_name: contractor.th_company_name,
          },
          due_ymd:      change_product_apply.due_ymd,
          completed_at: change_product_apply.completed_at,
        }
      },
      total_count: total_count
    }
  end

  def detail
    change_product_apply = ChangeProductApply.find(params[:change_product_apply_id])
    orders = change_product_apply.orders

    render json: {
      success: true,
      orders: orders.map {|order|
        applied_change_product = order.applied_change_product
        # 新しいスケジュールの算出
        new_installment = ChangeProductPaymentSchedule.new(order, applied_change_product).call

        {
          id: order.id,
          order_number: order.order_number,
          dealer_name: order.dealer.dealer_name,
          dealer_type: order.dealer.dealer_type_label,
          has_original_orders: order.has_original_orders?,
          due_ymd: change_product_apply.due_ymd,
          amount: order.purchase_amount.to_f,
          change_product_status: order.change_product_status_label,
          applied_change_product: {
            product_key:  applied_change_product.product_key,
            product_name: applied_change_product.product_name
          },
          before: {
            count: 1,
            schedule: [
              {
                due_ymd: order.change_product_first_due_ymd,
                amount: order.purchase_amount.to_f,
              }
            ]
          },
          after: {
            count: new_installment[:count],
            schedule: new_installment[:schedules],
            total_amount: new_installment[:total_amount],
          },
        }
      },
      memo: change_product_apply.memo,
      can_register: change_product_apply.can_register?,
      completed_at: change_product_apply.completed_at,
      register_user_name: change_product_apply.register_user&.user_name
    }
  end

  def approve
    # 権限チェック
    errors = check_permission_errors(login_user.md?).presence || []

    if errors.blank?
      errors, change_product_apply = RegisterAppliedChangeProduct.new(
        params[:change_product_apply_id],
        params[:orders],
        params[:memo],
        login_user
      ).call
    end

    if errors.blank?
      SendApprovalChangeProductSms.new(change_product_apply.reload).call

      render json: { success: true }
    else
      render json: { success: false, errors: errors }
    end
  end
end
