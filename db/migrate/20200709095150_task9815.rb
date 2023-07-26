class Task9815 < ActiveRecord::Migration[5.2]
  def change
    change_column_null :applied_dealers, :contractor_id, false
    change_column_null :applied_dealers, :dealer_id, false

    # ContractorのMain DealerをApplied Dealerとして登録する処理
    Contractor.all.each do |contractor|
      next if contractor.applied_dealers.present?

      contractor.applied_dealers.create!(
        dealer: contractor.main_dealer,
        sort_number: 1,
        applied_ymd: contractor.created_at.strftime('%Y%m%d'),
      )
    end
  end
end
