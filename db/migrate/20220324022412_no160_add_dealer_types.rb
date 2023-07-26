class No160AddDealerTypes < ActiveRecord::Migration[5.2]
  def up

    add_column :system_settings, :rakmao_terms_of_service_version, :integer, null: false,
      default: 1, after: :scgp_terms_of_service_version
   
    add_column :system_settings, :cotto_terms_of_service_version, :integer, null: false,
      default: 1, after: :rakmao_terms_of_service_version

    DealerTypeSetting.create!(
      dealer_type: :rakmao,
      dealer_type_code: 'rakmao',
      group_type: :cbm_group,
      switch_auto_approval: true,
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )

    DealerTypeSetting.create!(
      dealer_type: :cotto,
      dealer_type_code: 'cotto',
      group_type: :cbm_group,
      switch_auto_approval: true,
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )
  end

  def down
    remove_column :system_settings, :rakmao_terms_of_service_version, :integer
    remove_column :system_settings, :cotto_terms_of_service_version, :integer

    DealerTypeSetting.find_by(dealer_type: :rakmao)&.delete
    DealerTypeSetting.find_by(dealer_type: :cotto)&.delete
  end

end
