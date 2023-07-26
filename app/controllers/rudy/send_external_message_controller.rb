# frozen_string_literal: true

class Rudy::SendExternalMessageController < Rudy::ApplicationController
  def call
    tax_id = params.fetch(:tax_id)
    user_name = params[:username]
    message = params.fetch(:message)

    raise(ValidationError, 'too_long_message') if message.length > 500

    contractor = Contractor.after_registration.find_by(tax_id: tax_id)
    raise(ValidationError, 'contractor_not_found') if contractor.blank?

    if user_name.blank?
      # 指定Contractorの全てのContractorUserに送信
      # TODO sms_targetsをつけるか
      contractor.contractor_users.each do |contractor_user|
        send_message(contractor_user, message)
      end
    else
      # 指定ContractorUserに送信
      contractor_user = contractor.contractor_users.find_by(user_name: user_name)
      raise(ValidationError, 'invalid_user') if contractor_user.blank?
      # TODO UserType: Otherのチェックをするか
      send_message(contractor_user, message)
    end

    return render json: {
      result: "OK",
    }
  end

  private
  def send_message(contractor_user, message)
    if request_from_ssa?
      # SSA
      SendMessage.send_external_message_from_ssa(contractor_user, message)
    else
      # RUDY
      SendMessage.send_external_message_from_rudy(contractor_user, message)
    end
  end
end
