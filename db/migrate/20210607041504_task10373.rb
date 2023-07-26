class Task10373 < ActiveRecord::Migration[5.2]
  def change
    add_column :installments, :reduced_site_limit, :decimal, precision: 10, scale: 2, null: true, default: 0.0, after: :used_cashback

    # 既存のデータは対象外なので判定できるようにカラムをNULLにする(NULLは対象外として判定する)
    # Siteオーダーで元本への消し込みがあるinstallmentを対象外へ
    Installment.includes(:order).where.not(orders: { site_id: nil }, paid_principal: 0).update_all(reduced_site_limit: nil)
  end
end
