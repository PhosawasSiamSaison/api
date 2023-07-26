class OnlineApplyValidateAddress
  def self.createOneTimePasscord
    OneTimePasscode.create!(
      passcode: 6.times.map { SecureRandom.random_number(10) }.join,
      token: SecureRandom.urlsafe_base64,
      expires_at: Time.zone.now + JvService::Application.config.try(:online_apply_validate_address_limit_minutes).minutes
    )
  end
end