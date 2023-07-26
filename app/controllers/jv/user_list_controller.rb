# frozen_string_literal: true

class Jv::UserListController < ApplicationController
  before_action :auth_user
  before_action :parse_search_params, only: [:search]

  def search
    jv_users = JvUser.all

    paginated_jv_users, total_count = [
      jv_users.paginate(params[:page], jv_users, params[:per_page]), jv_users.count
    ]

    render json: {
      success:     true,
      jv_users:    format_jv_user_list(paginated_jv_users),
      total_count: total_count
    }
  end

  private

  def format_jv_user_list(jv_users)
    jv_users.map do |jv_user|
      {
        id:             jv_user.id,
        user_type:      jv_user.user_type_label,
        user_name:      jv_user.user_name,
        full_name:      jv_user.full_name,
        mobile_number:  jv_user.mobile_number,
        email:          jv_user.email,
        create_user_id: jv_user.create_user_id,
        update_user_id: jv_user.update_user_id,
        created_at:     jv_user.created_at,
        updated_at:     jv_user.updated_at
      }
    end
  end
end
