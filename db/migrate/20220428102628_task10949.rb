class Task10949 < ActiveRecord::Migration[5.2]
  def change
    add_column :terms_of_service_versions, :integrated, :boolean, null: false, default: false,
    after: :sub_dealer, comment: "統合版の規約タイプの判定カラム"

    add_column :system_settings, :integrated_terms_of_service_version, :integer, null: false,
      default: 1, after: :is_downloading_csv
  end
end
