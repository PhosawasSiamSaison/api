class SetSameContractorUser
  def initialize(params, contractor)
    @params = params
    @contractor = contractor
  end

  def call
    # Authorized Person の Same as
    if params[:contractor][:authorized_person_same_as_owner] == true
      contractor.authorized_person_name           = contractor.th_owner_name
      contractor.authorized_person_title_division = 'Owner'
      contractor.authorized_person_personal_id    = contractor.owner_personal_id
      contractor.authorized_person_email          = contractor.owner_email
      contractor.authorized_person_mobile_number  = contractor.owner_mobile_number
      contractor.authorized_person_line_id        = contractor.owner_line_id
    end

    # Contact Person の Same as
    if params[:contractor][:contact_person_same_as_owner] == true
      contractor.contact_person_name           = contractor.th_owner_name
      contractor.contact_person_title_division = 'Owner'
      contractor.contact_person_personal_id    = contractor.owner_personal_id
      contractor.contact_person_email          = contractor.owner_email
      contractor.contact_person_mobile_number  = contractor.owner_mobile_number
      contractor.contact_person_line_id        = contractor.owner_line_id
    elsif params[:contractor][:contact_person_same_as_authorized_person] == true
      contractor.contact_person_name           = contractor.authorized_person_name
      contractor.contact_person_title_division = contractor.authorized_person_title_division
      contractor.contact_person_personal_id    = contractor.authorized_person_personal_id
      contractor.contact_person_email          = contractor.authorized_person_email
      contractor.contact_person_mobile_number  = contractor.authorized_person_mobile_number
      contractor.contact_person_line_id        = contractor.authorized_person_line_id
    end
  end

  private
  attr_reader :params, :contractor
end
