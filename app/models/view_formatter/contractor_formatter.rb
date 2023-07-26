class ViewFormatter::ContractorFormatter
  @contractor = nil

  def initialize(contractor)
    @contractor = contractor
  end

  def format(contractor, ignore_attributes = [])
    result = {}
    contractor.attributes.each do |key, value|
      result[key] = value unless ignore_attributes.include?(key)
    end
    result
  end

  def format_more_information_with_hash(hash_for_merge = {})
    # 除外する項目
    result = format(@contractor, %w(
      lock_version
      update_user_id
      deleted
      created_at
      approval_user_id
      created_user_id
      register_user_id
      notes
      notes_update_user_id
      notes_updated_at
      reject_user_id
      create_user_id
      pool_amount
      doc_company_registration
      doc_vat_registration
      doc_owner_id_card
      doc_authorized_user_id_card
      doc_bank_statement
      doc_tax_report
      authorized_person_same_as_owner
      contact_person_same_as_owner
      contact_person_same_as_authorized_person
      check_payment
      qr_code_updated_at
      online_apply_token
    ))

    # enumが設定されている属性値をラベル化している
    result.merge!(
      application_type: @contractor.application_type_label,
      approval_status:  @contractor.approval_status_label,
      owner_sex:        @contractor.owner_sex_label,
      status:           @contractor.status_label
    )

    result.merge(hash_for_merge)
  end

  def format_update_with_hash(hash_for_merge = {})
    # 除外する項目
    result = format(@contractor, %w(
      lock_version
      update_user_id
      deleted
      created_at
      approval_user_id
      created_user_id
      register_user_id
      notes
      notes_update_user_id
      notes_updated_at
      reject_user_id
      create_user_id
      pool_amount
      application_type
      approval_status
      status
      registered_at
      approved_at
      rejected_at
      main_dealer_id
      check_payment
      qr_code_updated_at
    ))

    # enumが設定されている属性値をラベル化している
    result.merge!(owner_sex: @contractor.owner_sex_label)

    result.merge(hash_for_merge)
  end
end
