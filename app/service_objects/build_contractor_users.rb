class BuildContractorUsers

  attr_accessor :contractor, :create_user

  def initialize(contractor, create_user)
    @contractor  = contractor
    @create_user = create_user
  end

  def call
    # Owner
    owner                         = contractor.contractor_users.build(user_type: 'owner')
    owner.user_name               = contractor.owner_personal_id
    owner.full_name               = contractor.th_owner_name
    owner.mobile_number           = contractor.owner_mobile_number
    owner.title_division          = "Owner"
    owner.line_id                 = contractor.owner_line_id
    owner.email                   = contractor.owner_email

    temp_password                 = owner.generate_temp_password
    owner.password                = temp_password
    owner.temp_password           = temp_password
    owner.initialize_token = owner.generate_initialize_token
    owner.create_user             = create_user
    owner.update_user             = create_user

    # Authorized Person
    authorized_person = nil
    unless contractor.authorized_person_same_as_owner
      authorized_person = contractor.contractor_users.build(user_type: 'authorized')
      authorized_person.user_name               = contractor.authorized_person_personal_id
      authorized_person.full_name               = contractor.authorized_person_name
      authorized_person.mobile_number           = contractor.authorized_person_mobile_number
      authorized_person.title_division          = contractor.authorized_person_title_division
      authorized_person.line_id                 = contractor.authorized_person_line_id
      authorized_person.email                   = contractor.authorized_person_email

      authorized_person_password_value          = authorized_person.generate_temp_password
      authorized_person.password                = authorized_person_password_value
      authorized_person.temp_password           = authorized_person_password_value
      authorized_person.initialize_token = authorized_person.generate_initialize_token
      authorized_person.create_user             = create_user
      authorized_person.update_user             = create_user
    end

    [owner, authorized_person].compact
  end
end