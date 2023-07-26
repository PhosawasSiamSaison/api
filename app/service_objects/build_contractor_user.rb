class BuildContractorUser
  def initialize(params, login_user)
    @params = params
    @login_user = login_user
  end

  def call
    contractor_user = ContractorUser.new(contractor_user_params)

    temp_password   = contractor_user.generate_temp_password
    tax_id_token    = contractor_user.generate_initialize_token

    contractor_user.attributes = {
      user_type:     contractor_user.user_type.presence || 'other',
      password:      temp_password,
      temp_password: temp_password,
      initialize_token: tax_id_token,
      create_user: login_user,
      update_user: login_user,
    }

    contractor_user
  end

  private
  attr_accessor :params, :login_user

  def contractor_user_params
    params.require(:contractor_user).permit(
      :contractor_id,
      :user_name,
      :full_name,
      :mobile_number,
      :title_division,
      :email,
      :line_id,
      :user_type
    )
  end
end