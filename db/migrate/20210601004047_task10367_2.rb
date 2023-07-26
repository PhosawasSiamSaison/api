class Task103672 < ActiveRecord::Migration[5.2]
  def change
    # 既存のinstallmentはadjustできないようにする対応

    # used_exceededとused_cashbackのnullを許可する
    change_column_null :installments, :used_exceeded, from: false, to: true
    change_column_null :installments, :used_cashback, from: false, to: true

    # 既存のinstallmentはnullにする
    Installment.all.update_all(
      used_exceeded: nil,
      used_cashback: nil,
    )
  end
end
