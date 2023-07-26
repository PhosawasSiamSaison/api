class RemoveColumnEnNameFromContractorUsers < ActiveRecord::Migration[5.2]
  def change
    # いらなかったので削除
    remove_column :contractor_users, :en_name, :string

    change_column :contractors, :shareholders_equity, :decimal, precision: 15, scale: 2, null: true, default: nil
    change_column :contractors, :recent_revenue, :decimal, precision: 15, scale: 2, null: true, default: nil
    change_column :contractors, :short_term_loan, :decimal, precision: 15, scale: 2, null: true, default: nil
    change_column :contractors, :long_term_loan, :decimal, precision: 15, scale: 2, null: true, default: nil
    change_column :contractors, :recent_profit, :decimal, precision: 15, scale: 2, null: true, default: nil
  end
end
