# frozen_string_literal: true

class Contractor::CreditLimitDetailController < ApplicationController
  before_action :auth_user
  before_action :check_pdpa_version
  before_action :check_terms_of_service
  before_action :check_temp_password

  def detail
    contractor = login_user.contractor

    # 利用可能なDealer Type LimitとDealer情報を返す
    dealer_type_limits =
      contractor.use_only_credit_limit ? [] : formatted_dealer_type_limits(contractor)

    render json: {
      success: true,
      eligibility: {
        limit_amount: contractor.credit_limit_amount,
        used_amount: contractor.remaining_principal,
        available_balance: contractor.available_balance,
        delaer_type_limits: dealer_type_limits,
      }
    }
  end

  private
    def formatted_dealer_type_limits(contractor)

      contractor.enabled_limit_dealer_types.map do |dealer_type|
        # Dealerの一覧
        target_dealer_limits = contractor.latest_dealer_limits.includes(:dealer)
          .where(dealers: {dealer_type: dealer_type})

        {
          dealer_type_label: {
            code: dealer_type,
            label: ApplicationRecord.dealer_type_labels[dealer_type],
          },
          limit_amount:      contractor.dealer_type_limit_amount(dealer_type),
          used_amount:       contractor.dealer_type_remaining_principal(dealer_type),
          available_balance: contractor.dealer_type_available_balance(dealer_type),

          # Dealerの一覧
          dealers: target_dealer_limits.map do |dealer_limit|
            dealer = dealer_limit.dealer

            {
              id:                dealer.id,
              dealer_name:       dealer.dealer_name,
              limit_amount:      contractor.dealer_limit_amount(dealer),
              used_amount:       contractor.dealer_remaining_principal(dealer),
              available_balance: contractor.dealer_available_balance(dealer),
            }
          end
        }
      end
    end
end