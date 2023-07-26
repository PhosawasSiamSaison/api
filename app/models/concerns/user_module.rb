module UserModule
  def generate_auth_token
    loop do
      random_token = SecureRandom.urlsafe_base64
      break random_token unless AuthToken.exists?(token: random_token)
    end
  end

  def save_auth_token auth_token
    auth_tokens.create!(token: auth_token)
  end

  def generate_temp_password
    ((0..9).to_a).sample(6).join
  end

  def delete_with_auth_tokens
    auth_tokens.destroy_all

    update!(deleted: true)

    if is_a?(ContractorUser)
      # ContractorUserのマスキング
      update!(
        user_name: "0000000000000",
        full_name: "Deleted User #{id}",
        mobile_number: "0000000000",
        title_division: nil,
        email: nil,
        line_id: nil,
        line_user_id: nil,
        line_nonce: nil,
        initialize_token: nil,
        rudy_passcode: nil,
        rudy_auth_token: nil,
        password_digest: nil,
        temp_password: nil,
        deleted: true
      )
    else
      update!(deleted: true)
    end
  end
end
