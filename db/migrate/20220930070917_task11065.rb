class Task11065 < ActiveRecord::Migration[5.2]
  def change
    change_column_null :receive_amount_histories, :create_user_id, true, nil

    add_column :receive_amount_histories, :repayment_id, :string, limit: 32, null: true, after: :comment, comment: "RUDY 自動消し込み 重複チェック用"
    add_index :receive_amount_histories, :repayment_id, unique: true
  end
end
