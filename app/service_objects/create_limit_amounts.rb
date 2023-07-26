class CreateLimitAmounts
  def call(params, login_user)
    contractor = Contractor.find(params[:contractor_id])
    eligibilities = contractor.eligibilities

    eligibility_data = params.fetch(:eligibility)

    errors = []

    ActiveRecord::Base.transaction do
      eligibilities.latest.update!(latest: false) if eligibilities.latest.present?

      eligibility = eligibilities.build(
        limit_amount: eligibility_data[:limit_amount],
        class_type:   eligibility_data[:class_type],
        comment:      eligibility_data[:comment],
        create_user:  login_user,
      )

      if eligibility.save
        eligibility_data[:dealer_types].each do |dealer_type_params|
          dealer_type    = dealer_type_params[:dealer_type]
          limit_amount   = dealer_type_params[:limit_amount].to_f
          dealers_params = dealer_type_params[:dealers]

          # dealer_type_limitの作成
          eligibility.dealer_type_limits.create!(
            dealer_type:  dealer_type,
            limit_amount: limit_amount,
          )

          # dealer_limitの作成
          dealers_params.each do |dealer_params|
            dealer = Dealer.find(dealer_params[:id])

            if dealer.dealer_type.to_sym != dealer_type.to_sym
              errors = ["Unmatch Dealer Type. Dealer: #{dealer.dealer_name}"]
              raise 'Dealer TypeとDealerが一致しない'
            end

            eligibility.dealer_limits.create!(
              dealer_id:    dealer_params[:id],
              limit_amount: dealer_params[:limit_amount]
            )
          end
        end
      else
        errors = eligibility.error_messages
        raise ActiveRecord::Rollback
      end
    end

    errors
  end
end
