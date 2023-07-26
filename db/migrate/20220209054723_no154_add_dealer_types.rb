class No154AddDealerTypes < ActiveRecord::Migration[5.2]
  def up

    add_column :system_settings, :bigth_terms_of_service_version, :integer, null: false,
      default: 1, after: :nam_terms_of_service_version
   
    add_column :system_settings, :permsin_terms_of_service_version, :integer, null: false,
      default: 1, after: :bigth_terms_of_service_version

    add_column :system_settings, :scgp_terms_of_service_version, :integer, null: false,
      default: 1, after: :permsin_terms_of_service_version

    DealerTypeSetting.create!(
      dealer_type: :bigth,
      dealer_type_code: 'bigth',
      group_type: :cbm_group,
      switch_auto_approval: true,
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )

    DealerTypeSetting.create!(
      dealer_type: :permsin,
      dealer_type_code: 'permsin',
      group_type: :cbm_group,
      switch_auto_approval: true,
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )
    
    DealerTypeSetting.create!(
      dealer_type: :scgp,
      dealer_type_code: 'scgp',
      group_type: :cbm_group,
      switch_auto_approval: true,
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )
  end

  def down
    remove_column :system_settings, :bigth_terms_of_service_version, :integer
    remove_column :system_settings, :permsin_terms_of_service_version, :integer
    remove_column :system_settings, :scgp_terms_of_service_version, :integer

    DealerTypeSetting.find_by(dealer_type: :bigth)&.delete
    DealerTypeSetting.find_by(dealer_type: :permsin)&.delete
    DealerTypeSetting.find_by(dealer_type: :scgp)&.delete
  end

end
