class AuthDealerUser
  def initialize(dealer_user, password)
    @dealer_user = dealer_user
    @password    = password
  end

  def call
    dealer_user.present? && dealer_user.authenticate(password).present?
  end

  private

  attr_reader :dealer_user, :password
end
