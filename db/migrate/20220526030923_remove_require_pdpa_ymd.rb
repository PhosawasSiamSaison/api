class RemoveRequirePdpaYmd < ActiveRecord::Migration[5.2]
  def change
    remove_column :system_settings, :require_pdpa_ymd, :string
  end
end
