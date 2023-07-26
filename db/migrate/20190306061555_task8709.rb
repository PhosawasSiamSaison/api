class Task8709 < ActiveRecord::Migration[5.2]
  def change
    # owner_address の文字数を変更
    remove_column :contractors, :owner_address, :string
    add_column    :contractors, :owner_address, :string, limit: 200, after: :en_owner_name

    # owner_sex を owner_address の次に移動
    remove_column :contractors, :owner_sex, :integer
    add_column    :contractors, :owner_sex, :integer, limit: 1, null: false, after: :owner_address

    # owner_birth_ymd を owner_sex の次に移動
    remove_column :contractors, :owner_birth_ymd, :string
    add_column    :contractors, :owner_birth_ymd, :string, limit: 8, after: :owner_sex

    # owner_email を owner_personal_id の次に移動
    remove_column :contractors, :owner_email, :string
    add_column    :contractors, :owner_email, :string, limit: 200, after: :owner_personal_id

    # owner_mobile_number を owner_email の次に移動
    remove_column :contractors, :owner_mobile_number, :string
    add_column    :contractors, :owner_mobile_number, :string, limit: 15, after: :owner_email

    # authorized_person_full_name を authorized_person_name へ変更
    remove_column :contractors, :authorized_person_full_name, :string
    add_column    :contractors, :authorized_person_name, :string, limit: 40, after: :owner_line_id

    # authorized_person_title_division の文字数を変更
    remove_column :contractors, :authorized_person_title_division, :string
    add_column    :contractors, :authorized_person_title_division, :string, limit: 40, after: :authorized_person_name

    # authorized_person_personal_id を authorized_person_title_division の次に移動
    remove_column :contractors, :authorized_person_personal_id, :string
    add_column    :contractors, :authorized_person_personal_id, :string, limit: 20, after: :authorized_person_title_division

    # authorized_person_email を追加
    add_column :contractors, :authorized_person_email, :string, limit: 200, after: :authorized_person_personal_id

    # contact_person_title_division を 追加
    add_column :contractors, :contact_person_title_division, :string, limit: 40, after: :contact_person_name

    # contact_person_personal_id を contact_person_title_division の次に移動
    remove_column :contractors, :contact_person_personal_id, :string
    add_column    :contractors, :contact_person_personal_id, :string, limit: 20, after: :contact_person_title_division


    # Same as
    add_column :contractors, :authorized_person_same_as_owner,          :boolean, null: false,
      default: false, after: :owner_line_id
    add_column :contractors, :contact_person_same_as_owner,             :boolean, null: false,
      default: false, after: :authorized_person_line_id
    add_column :contractors, :contact_person_same_as_authorized_person, :boolean, null: false,
      default: false, after: :contact_person_same_as_owner


    # Remove Docs
    remove_column :contractors, :doc_company_registration_certificate, :boolean, null: false
    remove_column :contractors, :doc_copy_of_tax_certificate, :boolean, null: false
    remove_column :contractors, :doc_copy_of_id_card, :boolean, null: false
    remove_column :contractors, :doc_bank_statement, :boolean, null: false
    remove_column :contractors, :doc_tax_report, :boolean, null: false

    # Add Docs
    add_column :contractors, :doc_company_registration,    :boolean, null: false, default: false, after: :call_required
    add_column :contractors, :doc_vat_registration,        :boolean, null: false, default: false, after: :doc_company_registration
    add_column :contractors, :doc_owner_id_card,           :boolean, null: false, default: false, after: :doc_vat_registration
    add_column :contractors, :doc_authorized_user_id_card, :boolean, null: false, default: false, after: :doc_owner_id_card
    add_column :contractors, :doc_bank_statement,          :boolean, null: false, default: false, after: :doc_authorized_user_id_card
    add_column :contractors, :doc_financial_statement,     :boolean, null: false, default: false, after: :doc_bank_statement
  end
end
