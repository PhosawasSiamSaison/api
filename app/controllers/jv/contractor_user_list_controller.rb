# frozen_string_literal: true

class Jv::ContractorUserListController < ApplicationController
  before_action :auth_user

  def search
    contractor = Contractor.find(params[:contractor_id])
    contractor_users = contractor.contractor_users

    paginated_contractor_users, total_count = [
      contractor_users.paginate(params[:page], contractor_users, params[:per_page]), contractor_users.count
    ]

    fomatted_contractor_users = paginated_contractor_users.map do |contractor_user|
      {
        id:             contractor_user.id,
        user_name:      contractor_user.user_name,
        full_name:      contractor_user.full_name,
        mobile_number:  contractor_user.mobile_number,
        title_division: contractor_user.title_division,
        email:          contractor_user.email,
        line_id:        contractor_user.line_id,
        user_type:      contractor_user.user_type_label,
        verify_mode:    contractor_user.verify_mode_label,
        line_linked:    contractor_user.is_linked_line_account?,
        agreed_pdpa:    contractor_user.agreed_latest_pdpa?
      }
    end

    render json: {
      success: true,
      contractor: {
        id:              contractor.id,
        tax_id:          contractor.tax_id,
        th_company_name: contractor.th_company_name,
        en_company_name: contractor.en_company_name
      },
      contractor_users: fomatted_contractor_users,
      total_count: total_count
    }
  end
end
