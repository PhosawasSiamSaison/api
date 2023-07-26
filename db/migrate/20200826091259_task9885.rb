class Task9885 < ActiveRecord::Migration[5.2]
  def change
    add_column :system_settings, :solution_switch_auto_approval, :boolean, null: false,
      default: true, after: :transformer_switch_auto_approval

    add_column :system_settings, :solution_terms_of_service_version, :integer, null: false,
      default: 1, after: :transformer_terms_of_service_version
  end
end
