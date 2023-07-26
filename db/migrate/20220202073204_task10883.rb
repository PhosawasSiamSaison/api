class Task10883 < ActiveRecord::Migration[5.2]
  def change
    add_column :dealer_type_settings, :switch_auto_approval, :boolean,
      null: false, default: true, after: :dealer_type_code

    remove_column :system_settings, :cbm_switch_auto_approval, :boolean
    remove_column :system_settings, :cpac_switch_auto_approval, :boolean
    remove_column :system_settings, :global_house_switch_auto_approval, :boolean
    remove_column :system_settings, :transformer_switch_auto_approval, :boolean
    remove_column :system_settings, :solution_switch_auto_approval, :boolean
    remove_column :system_settings, :b2b_switch_auto_approval, :boolean
    remove_column :system_settings, :q_mix_switch_auto_approval, :boolean
    remove_column :system_settings, :nam_switch_auto_approval, :boolean
  end
end
