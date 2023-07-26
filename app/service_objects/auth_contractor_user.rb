class AuthContractorUser
  def initialize(contractor_user, password)
    @contractor_user = contractor_user
    @password = password
  end

  def call
    return false if contractor_user.blank? || password.blank?

    result = contractor_user.authenticate(password).present?

    if !result
      # JV-serviceの認証に失敗した場合は、RUDYで認証をする
      result = RudyLogin.new(contractor_user.user_name, password).exec
    end

    result
  end

  private
  attr_reader :contractor_user, :password

  def contractor_user
    @contractor_user
  end
end
