class Task10301 < ActiveRecord::Migration[5.2]
  def up
    add_column :system_settings, :nam_switch_auto_approval, :boolean, null: false,
      default: false, after: :q_mix_switch_auto_approval

    add_column :system_settings, :nam_terms_of_service_version, :integer, null: false,
      default: 1, after: :q_mix_terms_of_service_version

    DealerTypeSetting.create!(
      dealer_type: :nam,
      dealer_type_code: 'nam',
      sms_line_account: '@siamsaison',
      sms_contact_info: '02-586-3021 หรือ ทางไลน์ Official @Siamsaison',
      sms_servcie_name: 'SAISON CREDIT', # CPAC以外は SAISON CREDIT
    )
  end

  def down
    remove_column :system_settings, :nam_switch_auto_approval, :boolean
    remove_column :system_settings, :nam_terms_of_service_version, :integer

    DealerTypeSetting.find_by(dealer_type: :nam)&.delete
  end
end
