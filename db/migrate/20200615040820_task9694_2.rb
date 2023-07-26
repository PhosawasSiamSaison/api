class Task96942 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :sub_dealer_terms_of_service_version, :integer, null: false, default: 1, after: :q_mix_terms_of_service_version
    add_column :terms_of_service_versions, :version, :integer, null: false, after: :sub_dealer
    remove_column :contractor_users, :terms_of_service_version, :integer
  end
end
