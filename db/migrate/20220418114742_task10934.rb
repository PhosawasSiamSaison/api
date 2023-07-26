class Task10934 < ActiveRecord::Migration[5.2]
  def change
    change_column_null :contractors, :owner_sex, true

    add_column :contractors, :shareholders_equity, :decimal, precision: 10, scale: 2, null: true,
      default: 0.0, after: :capital_fund_mil

    add_column :contractors, :recent_revenue, :decimal, precision: 10, scale: 2, null: true,
      default: 0.0, after: :shareholders_equity

    add_column :contractors, :short_term_loan, :decimal, precision: 10, scale: 2, null: true,
      default: 0.0, after: :recent_revenue

    add_column :contractors, :long_term_loan, :decimal, precision: 10, scale: 2, null: true,
      default: 0.0, after: :short_term_loan

    add_column :contractors, :recent_profit, :decimal, precision: 10, scale: 2, null: true,
      default: 0.0, after: :long_term_loan

    add_column :contractors, :apply_from, :string, length: 100, null: true,
      default: nil, after: :recent_profit


    add_column :contractor_users, :en_name, :string, length: 40, null: true, default: "", after: :full_name
  end
end
