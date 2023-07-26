class Task9555 < ActiveRecord::Migration[5.2]
  def up
    add_column :system_settings, :cbm_terms_of_service_version, :integer, null: false, default: 0, after: :terms_of_service_version
    add_column :system_settings, :cpac_terms_of_service_version, :integer, null: false, default: 0, after: :cbm_terms_of_service_version

    if SystemSetting.first.present?
      SystemSetting.update!(
        cbm_terms_of_service_version: SystemSetting.terms_of_service_version,
        cpac_terms_of_service_version: SystemSetting.terms_of_service_version,
      )
    end

    remove_column :system_settings, :terms_of_service_version
  end
 
  def down
    add_column :system_settings, :terms_of_service_version, :integer, null: false, default: 0, after: :cpac_terms_of_service_version

    SystemSetting.update!(
      terms_of_service_version: SystemSetting.cbm_terms_of_service_version,
    )

    remove_column :system_settings, :cbm_terms_of_service_version
    remove_column :system_settings, :cpac_terms_of_service_version
  end
end
