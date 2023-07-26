class RenameColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :contractors, :is_rakmao, :use_only_credit_limit
    rename_column :contractors, :doc_financial_statement, :doc_tax_report
  end
end
