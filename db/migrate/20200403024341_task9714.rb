class Task9714 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :cbm_switch_auto_approval,          :boolean, null: false, default: false, after: :global_house_terms_of_service_version
    add_column :system_settings, :cpac_switch_auto_approval,         :boolean, null: false, default: true,  after: :cbm_switch_auto_approval
    add_column :system_settings, :global_house_switch_auto_approval, :boolean, null: false, default: false, after: :cpac_switch_auto_approval
  end
end
