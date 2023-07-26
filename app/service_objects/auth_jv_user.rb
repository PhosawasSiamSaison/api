class AuthJvUser
  def initialize(jv_user, password)
    @jv_user = jv_user
    @password = password
  end

  def call
    jv_user.present? && jv_user.authenticate(password).present?
  end

  private
  attr_reader :jv_user, :password

  def jv_user
    @jv_user
  end
end
