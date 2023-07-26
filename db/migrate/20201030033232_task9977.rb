class Task9977 < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :uniq_check_flg, :boolean, null: true, default: true,
      after: :rudy_purchase_ymd, comment: 'ユニークチェックから外す場合はnullにする'

    # 重複があるとインデックスの追加に失敗するので先にuniq_check_flgを更新する
    Order.unscope(where: :deleted).where(deleted: 1).update_all(uniq_check_flg: nil)
    Order.where.not(canceled_at: nil).update_all(uniq_check_flg: nil)

    add_index :orders, [:order_number, :dealer_id, :uniq_check_flg], unique: true
  end
end
