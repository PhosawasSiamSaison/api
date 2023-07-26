class Task9681 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :global_house_terms_of_service_version, :integer, null: false,
      default: 1, after: :cpac_terms_of_service_version
  end
end
