class AddBooleanColumnsToContractor < ActiveRecord::Migration[5.2]
  def change
    add_column :contractors, :doc_company_registration_certificate, :boolean, default: false, after: :call_required
    add_column :contractors, :doc_copy_of_tax_certificate, :boolean, default: false, after: :doc_company_registration_certificate
    add_column :contractors, :doc_copy_of_id_card, :boolean, default: false, after: :doc_copy_of_tax_certificate
    add_column :contractors, :doc_bank_statement, :boolean, default: false, after: :doc_copy_of_id_card
    add_column :contractors, :doc_tax_report, :boolean, default: false, after: :doc_bank_statement
  end
end
