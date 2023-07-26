# frozen_string_literal: true

class Contractor::UserListController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def user_list
    contractor_users = login_user.contractor.contractor_users

    render json: { success: true, contractor_users: format_contractor_user_list(contractor_users) }
  end

  private

  def format_contractor_user_list(contractor_users)
    contractor_users.map do |contractor_user|
      {
        id:             contractor_user.id,
        user_name:      contractor_user.user_name,
        full_name:      contractor_user.full_name,
        title_division: contractor_user.title_division,
        user_type:      contractor_user.user_type_label,
        mobile_number:  contractor_user.mobile_number,
        email:          contractor_user.email,
        line_id:        contractor_user.line_id
      }
    end
  end
end
