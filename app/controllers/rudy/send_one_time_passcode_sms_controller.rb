# frozen_string_literal: true

class Rudy::SendOneTimePasscodeSmsController < Rudy::ApplicationController
  def call
    return render_demo_response if get_demo_bearer_token?

    username = params[:username]

    contractor_user = ContractorUser.find_by(user_name: username)
    raise(ValidationError, 'invalid_user') if contractor_user.blank?

    contractor = contractor_user.contractor
    raise(ValidationError, 'contractor_unavailable') if !contractor.active?

    if contractor_user.use_verify_otp_mode?
      rudy_passcode = contractor_user.gen_rudy_passcode

      contractor_user.update!(
        rudy_passcode: rudy_passcode,
        rudy_passcode_created_at: Time.zone.now,
      )

      SendMessage.send_one_time_passcode(contractor_user, rudy_passcode)

      render json: {
        result: "OK",
        header_text: RudyApiSetting.response_header_text,
        text: RudyApiSetting.response_text,
      }
    else
      raise(ValidationError, 'otp_unavailable')
    end
  end

  private
  def render_demo_response
    username = params[:username]

    # Success
    if username == 'user1'
      return render json: {
        result: "OK",
        header_text: "กรุณาติดต่อ SAISON",
        text: "ในกรณีที่คุณลืมรหัสผ่านกรุณาติดต่อ SAISON เพื่อขอรหัสผ่านใหม่ในการเข้าระบบ\nโทร: 099-4444 4455 (** ติดต่อได้ตลอดชั่วโมง **)",
      }
    end

    # Error : invalid_user
    raise(ValidationError, 'invalid_user') if username == 'user2'

    # Error : contractor_unavailable
    raise(ValidationError, 'contractor_unavailable') if username == 'user3'

    # Error : not_agreed
    raise(ValidationError, 'not_agreed')if username == 'user4'

    # 一致しない
    raise NoCaseDemo
  end
end
