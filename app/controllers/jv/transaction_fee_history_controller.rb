class Jv::TransactionFeeHistoryController < ApplicationController
  before_action :auth_user

  def transaction_fees
    transaction_fees = TransactionFeeHistory
                        .apply_ymd_sort
                        .where(dealer_id: params[:dealer_id], status: ["scheduled", "active"])
    render json: { 
      success: true,
      transaction_fees: format_transaction_fees(transaction_fees)
    }
  end

  def transaction_fee_histories
    transaction_fee_histories = TransactionFeeHistory
                                .unscope(where: :deleted)
                                .apply_ymd_sort
                                .where(dealer_id: params[:dealer_id])
    render json: { 
      success: true,
      transaction_fee_histories: format_transaction_fees(transaction_fee_histories)
    }
  end
  
  def create_transaction_fee_history
    transaction_fee_history = TransactionFeeHistory.new(transaction_fee_history_params)

    transaction_fee_history.attributes = { create_user: login_user, update_user: login_user }

    if transaction_fee_history.save
      render json: { success: true }
    else
      render json: { success: false, errors: transaction_fee_history.error_messages }
    end
  end

  def delete_transaction_fee_history
    transaction_fee_history = TransactionFeeHistory.find_by(id: params[:id])

    today_ymd = BusinessDay.today_ymd

    unless transaction_fee_history.present?
      return render json: { 
        success: false,
        errors: "record not found"
      }
    end

    if transaction_fee_history.apply_ymd <= today_ymd
      return render json: { 
        success: false,
        errors: "can't delete in use Transaction Fee History" }
    end

    transaction_fee_history.attributes = { update_user: login_user }
    transaction_fee_history.delete_history

    render json: { success: true }
  end

  private

  def transaction_fee_history_params
    params.require(:transaction_fee_history)
          .permit(
            :dealer_id,
            :apply_ymd,
            :for_normal_rate,
            :for_government_rate,
            :for_sub_dealer_rate,
            :for_individual_rate,
            :reason
          )
  end

  def format_transaction_fees(transaction_fees)
    transaction_fees.map do |transaction_fee|
      {
        id: transaction_fee.id,
        apply_ymd:  transaction_fee.apply_ymd,
        for_normal_rate: transaction_fee.for_normal_rate,
        for_government_rate: transaction_fee.for_government_rate,
        for_sub_dealer_rate: transaction_fee.for_sub_dealer_rate,
        for_individual_rate: transaction_fee.for_individual_rate,
        status: transaction_fee.status,
        create_user_name:   transaction_fee&.create_user&.full_name,
        update_user_name:   transaction_fee&.update_user&.full_name,
        created_at: transaction_fee.created_at,
        updated_at: transaction_fee.updated_at,
        lock_version:       transaction_fee.lock_version
      }
    end
  end
end
