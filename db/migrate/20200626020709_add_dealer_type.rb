class AddDealerType < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :transformer_switch_auto_approval, :boolean, null: false,
      default: false, after: :global_house_switch_auto_approval
    add_column :system_settings, :transformer_terms_of_service_version, :integer, null: false,
      default: 1, after: :global_house_terms_of_service_version

  end
end
