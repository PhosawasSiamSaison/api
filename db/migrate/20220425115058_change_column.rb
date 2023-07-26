class ChangeColumn < ActiveRecord::Migration[5.2]
  def change
    change_column :contractors, :shareholders_equity, :decimal, precision: 20, scale: 2, null: true, default: nil
    change_column :contractors, :recent_revenue, :decimal, precision: 20, scale: 2, null: true, default: nil
    change_column :contractors, :short_term_loan, :decimal, precision: 20, scale: 2, null: true, default: nil
    change_column :contractors, :long_term_loan, :decimal, precision: 20, scale: 2, null: true, default: nil
    change_column :contractors, :recent_profit, :decimal, precision: 20, scale: 2, null: true, default: nil

    change_column :contractors, :th_company_name, :string, limit: 100
    change_column :contractors, :en_company_name, :string, limit: 100
    change_column :contractors, :address, :string, limit: 200
  end
end
