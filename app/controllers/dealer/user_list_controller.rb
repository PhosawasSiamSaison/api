# frozen_string_literal: true

class Dealer::UserListController < ApplicationController
  before_action :auth_user

  def user_list
    dealer_users = login_user.dealer.dealer_users

    render json: { success: true, dealer_users: format_dealer_user_list(dealer_users) }
  end

  private

  def format_dealer_user_list(dealer_users)
    dealer_users.map do |dealer_user|
      {
        id:            dealer_user.id,
        user_type:     dealer_user.user_type_label,
        user_name:     dealer_user.user_name,
        full_name:     dealer_user.full_name,
        mobile_number: dealer_user.mobile_number,
        email:         dealer_user.email,
        created_at:    dealer_user.created_at,
        updated_at:    dealer_user.updated_at
      }
    end
  end
end
