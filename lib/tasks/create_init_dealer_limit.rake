desc 'Main Dealerに対して、Dealer Type & DealerのCredit Limitを設定(運用)'
task create_init_dealer_limit: :environment do
  contractors = Contractor.all

  contractors.each do |contractor|
    eligibility  = contractor.eligibilities.latest
    limit_amount = contractor.credit_limit_amount
    dealer       = contractor.main_dealer
    dealer_type  = dealer.dealer_type

    if eligibility.blank?
      p "tax_id: #{contractor.tax_id} のContractorは、Credit Limitが設定されていません"
      next
    end

    if limit_amount <= 0.0
      p "tax_id: #{contractor.tax_id} のContractorは、Credit Limitが0.0です"
      next
    end

    begin
      if contractor.latest_dealer_type_limits&.find_by(dealer_type: dealer_type).blank?        
        eligibility.dealer_type_limits.create!(
          dealer_type:  dealer_type,
          limit_amount: limit_amount,
        )
      end

      if contractor.latest_dealer_limits&.find_by(dealer: dealer).blank?
        eligibility.dealer_limits.create!(
          dealer_id:    dealer.id,
          limit_amount: limit_amount
        )
      end
    rescue Exception => e
      error_msg
      p e
      next
    end
  end

  p '完了'
end

def error_msg
  p "!!! エラー !!!"
end