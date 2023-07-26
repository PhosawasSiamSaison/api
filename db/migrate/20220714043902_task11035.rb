class Task11035 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :individual_terms_of_service_version, :integer, null: false,
      default: 1, after: :sub_dealer_terms_of_service_version

    add_column :terms_of_service_versions, :individual, :boolean, default: false, null: false,
      after: :integrated
  end
end
