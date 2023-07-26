class No204205AddChangeDealerTypes < ActiveRecord::Migration[5.2]
  def up
   
    add_column :system_settings, :d_gov_terms_of_service_version, :integer, null: false,
      default: 1, after: :cotto_terms_of_service_version

    DealerTypeSetting.create!(
      dealer_type: :d_gov,
      dealer_type_code: 'd_gov',
      group_type: :project_group,
      switch_auto_approval: true,
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )

    GlobalAvailableSetting.insert_category_data(insert_data)
  end

  def down
    remove_column :system_settings, :d_gov_terms_of_service_version, :integer

    DealerTypeSetting.find_by(dealer_type: :d_gov)&.delete
  end

  private
  def insert_data
    {
      normal:     category_data(:normal),
      sub_dealer: category_data(:sub_dealer),
      individual: category_data(:individual),
      government: category_data(:government)
    }
  end

  def category_data(contractor_type)
    {
      purchase: {
        d_gov:     { 1 => true,  4 => false, 5 => false, 2 => false, 3 => false, 6 =>  true, 7 =>  true, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false }
      },
      switch: {
        d_gov:     { 1 => false, 4 =>  true, 5 => false, 2 =>  true, 3 => false, 6 =>  true, 7 =>  true, 8 => false, 11=>false, 9 => false, 10 => false, 12 => false }
      },
      cashback: {
        d_gov:    false
      }
    }
  end

end
