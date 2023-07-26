# frozen_string_literal: true

class Rudy::VerifyAccountController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    username = params[:username]
    passcode = params[:one_time_passcode]

    contractor_user = ContractorUser.find_by(user_name: username)
    raise(ValidationError, 'invalid_user') if contractor_user.blank?

    contractor = contractor_user.contractor
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    if contractor_user.use_verify_otp_mode?
      # パスコードの検証
      raise(ValidationError, 'invalid_passcode') if !contractor_user.valid_passcode?(passcode)

      # パスコードの期限チェック
      raise(ValidationError, 'expired_passcode') if contractor_user.expired_passcode?
    else
      # ログインパスコードで検証
      unless AuthContractorUser.new(contractor_user, passcode).call
        raise(ValidationError, 'invalid_passcode')
      end
    end

    # 認証成功
    auth_token = generate_rudy_auth_token
    contractor_user.update!(rudy_auth_token: auth_token, rudy_passcode: nil)

    render json: {
      result: "OK",
      header_text: RudyApiSetting.response_header_text,
      text: RudyApiSetting.response_text,
      auth_token: auth_token,
    }
  end

  private
  def generate_rudy_auth_token
    loop do
      random_token = SecureRandom.urlsafe_base64
      break random_token unless ContractorUser.exists?(rudy_auth_token: random_token)
    end
  end

  def render_demo_response
    username = params[:username]

    # Success
    if username == 'user1'
      return render json: {
        result: "OK",
        header_text: "กรุณาติดต่อ SAISON",
        text: "ในกรณีที่คุณลืมรหัสผ่านกรุณาติดต่อ SAISON เพื่อขอรหัสผ่านใหม่ในการเข้าระบบ\nโทร: 099-4444 4455 (** ติดต่อได้ตลอดชั่วโมง **)",
        auth_token: "veu6AicohweeFoh"
      }
    end

    # Error : invalid_user
    raise(ValidationError, 'invalid_user') if username == 'user2'

    # Error : contractor_unavailable
    raise(ValidationError, 'contractor_unavailable') if username == 'user3'

    # Error : invalid_passcode
    raise(ValidationError, 'invalid_passcode') if username == 'user4'

    # Error : expired_passcode
    raise(ValidationError, 'expired_passcode') if username == 'user5'

    # 一致しない
    raise NoCaseDemo
  end
end
