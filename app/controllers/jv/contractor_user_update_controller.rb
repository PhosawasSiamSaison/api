# frozen_string_literal: true

class Jv::ContractorUserUpdateController < ApplicationController
  before_action :auth_user

  def contractor_user
    contractor_user = ContractorUser.find(params['contractor_user_id'])

    render json: {
      success: true,
      contractor_user: {
        id:              contractor_user.id,
        user_name:       contractor_user.user_name,
        full_name:       contractor_user.full_name,
        mobile_number:   contractor_user.mobile_number,
        title_division:  contractor_user.title_division,
        email:           contractor_user.email,
        line_id:         contractor_user.line_id,
        user_type:       contractor_user.user_type_label,
        line_linked:     contractor_user.is_linked_line_account?,
        updated_at:      contractor_user.updated_at,
        update_user_name: contractor_user.update_user&.full_name
      }
    }
  end

  def update_contractor_user
    contractor_user = ContractorUser.find(params[:contractor_user][:id])

    contractor_user.attributes = { update_user: login_user }

    if contractor_user.update(contractor_user_update_params)
      render json: { success: true }
    else
      render json: { success: false, errors: contractor_user.error_messages }
    end
  end

  def delete_contractor_user
    contractor_user = ContractorUser.find(params['contractor_user_id'])

    contractor_user.delete_with_auth_tokens

    render json: { "success": true }
  end


  private
  def contractor_user_update_params
    params.require(:contractor_user)
      .permit(:user_name, :full_name, :mobile_number, :title_division, :line_id, :user_type, :email)
  end
end
