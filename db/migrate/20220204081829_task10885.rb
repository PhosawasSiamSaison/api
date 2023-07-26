class Task10885 < ActiveRecord::Migration[5.2]
  def up
    # コメントを追加
    change_column :dealer_type_settings, :dealer_type_code, :string, limit: 40,
      comment: 'クライアントツールで分類を見やすくするためのカラム'

    add_column :dealer_type_settings, :group_type, :integer, limit: 1, null: false, default: 0,
      after: :dealer_type_code

    # CBM系
    DealerTypeSetting.find_by(dealer_type: :cbm).update!(group_type: :cbm_group)
    DealerTypeSetting.find_by(dealer_type: :global_house).update!(group_type: :cbm_group)
    DealerTypeSetting.find_by(dealer_type: :transformer).update!(group_type: :cbm_group)
    # CPAC系
    DealerTypeSetting.find_by(dealer_type: :cpac).update!( group_type: :cpac_group)
    DealerTypeSetting.find_by(dealer_type: :q_mix).update!(group_type: :cpac_group)
    DealerTypeSetting.find_by(dealer_type: :nam).update!(group_type: :cpac_group)
    # Project系
    DealerTypeSetting.find_by(dealer_type: :solution).update!(group_type: :project_group)
    DealerTypeSetting.find_by(dealer_type: :b2b).update!(group_type: :project_group)
  end

  def down
    remove_column :dealer_type_settings, :group_type, :integer
  end
end
