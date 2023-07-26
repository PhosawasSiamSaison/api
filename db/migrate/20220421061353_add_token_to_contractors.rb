class AddTokenToContractors < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :online_apply_token, :string, limit: 30, null: true, default: nil,
      unique: true, after: :update_user_id, comment: "本人確認画像のアップロード時に必要"
  end
end
