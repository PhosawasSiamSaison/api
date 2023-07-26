# frozen_string_literal: true

class OnlineApply::IndexController < OnlineApply::ApplicationController
  include ImageModule

  def check_tax_id
    tax_id = params.fetch(:tax_id)

    contractor = Contractor.new(tax_id: tax_id)

    contractor.valid?
    tax_id_errors = contractor.errors.details[:tax_id]

    if tax_id_errors.blank?
      render json: { success: true }
    else
      # 重複エラーがある場合
      if tax_id_errors.find{|error| error[:error] == :taken}
        render json: { success: false, error: "tax_id_already_taken"}
      else
        # その他のバリデーションエラー
        render json: { success: false, error: "invalid_tax_id"}
      end
    end
  end

  # National ID(user_name)が登録済みかをチェックする
  def check_national_id
    user_name = params.fetch(:national_id)

    contractor_user = ContractorUser.new(user_name: user_name)

    contractor_user.valid?
    user_name_errors = contractor_user.errors.details[:user_name]

    if user_name_errors.blank?
      render json: { success: true }
    else
      # 重複エラーがある場合
      if user_name_errors.find{|error| error[:error] == :taken}
        render json: { success: false, error: "national_id_already_taken"}
      else
        # その他のバリデーションエラー
        render json: { success: false, error: "invalid_national_id"}
      end
    end
  end

  def send_validation_email
    applicant_name = params.fetch(:applicant_name)
    email = params.fetch(:email)
    return render json: { success: false, error: 'invalid_email' } unless email.match(URI::MailTo::EMAIL_REGEXP)

    one_time_passcord = OnlineApplyValidateAddress.createOneTimePasscord

    SendMail.send_online_apply_one_time_passcode(email, one_time_passcord.passcode, applicant_name)

    render json: { success: true, token: one_time_passcord.token }
  end

  def send_validation_sms
    phone_number = params.fetch(:phone_number)
    return render json: { success: false, error: 'invalid_phone_number' } unless phone_number.match('^([0-9]{10}|[0-9]{11})$')

    one_time_passcord = OnlineApplyValidateAddress.createOneTimePasscord

    SendMessage.send_online_apply_one_time_passcode(phone_number, one_time_passcord.passcode)

    render json: { success: true, token: one_time_passcord.token }
  end

  def validate_passcode
    passcode = params.fetch(:passcode)
    token = params.fetch(:token)

    one_time_passcode = OneTimePasscode.find_by(token: token)

    return render json: { success: false, error: 'invalid_token' } unless one_time_passcode
    return render json: { success: false, error: 'invalid_passcode' } unless passcode == one_time_passcode.passcode
    return render json: { success: false, error: 'passcode_expired' } if one_time_passcode.expired?

    render json: { success: true }
  end

  def create_contractor
    error, contractor = RegisterOnlineProcessingContractor.new.call(params)

    unless error
      # 本人確認画像アップロードリンクの送信
      SendMessage.send_identity_verification_link(contractor)
    end

    unless error
      render json: { success: true, auth_token: contractor.online_apply_token }
    else
      render json: { success: false, error: error }
    end
  end

  # 本人画像の登録
  def upload_selfie_image
    auth_token = params.fetch(:auth_token)
    data       = params.fetch(:data)
    filename   = params.fetch(:filename)

    contractor = Contractor.find_by(online_apply_token: auth_token)
    return render json: { success: false, error: 'invalid_token'} unless contractor

    ActiveRecord::Base.transaction do
      contractor.selfie_image.attach(io: parse_base64(data), filename: filename)

      # 画像のアップロードが完了していれば後続処理を実行する
      done_online_apply(contractor) if uploaded_identification_images?(contractor)
    end

    notify_online_apply_result(contractor) if uploaded_identification_images?(contractor)

    render json: {
      success: true,
      image_url: url_for(contractor.selfie_image),
    }
  end

  # National IDカード画像の登録
  def upload_card_image
    auth_token = params.fetch(:auth_token)
    data       = params.fetch(:data)
    filename   = params.fetch(:filename)

    contractor = Contractor.find_by(online_apply_token: auth_token)
    return render json: { success: false, error: 'invalid_token'} unless contractor

    ActiveRecord::Base.transaction do
      contractor.national_card_image.attach(io: parse_base64(data), filename: filename)

      # 画像のアップロードが完了していれば後続処理を実行する
      done_online_apply(contractor) if uploaded_identification_images?(contractor)
    end

    notify_online_apply_result(contractor) if uploaded_identification_images?(contractor)

    render json: {
      success: true,
      image_url: url_for(contractor.national_card_image),
    }
  end

  private
    # 本人確認画像が２つともアップロードされているかの判定
    def uploaded_identification_images? contractor
      contractor.selfie_image.attached? && contractor.national_card_image.attached?
    end

    def done_online_apply contractor
      # オンライン申請完了の処理

      contractor.online_apply_token = nil

      error, scoring_result = Scoring.new(contractor.id).exec

      # スコアリングエラー(APIエラー)
      return contractor.update!(approval_status: :processing) if error

      # reject
      return RejectContractor.new(contractor, nil).call if scoring_result.reject_class?

      # スコアあり or pending
      contractor.update!(approval_status: :processing)

      # スコアあり
      unless scoring_result.pending_class?
        contractor.create_eligibility(scoring_result.limit_amount, scoring_result.class_type, 'Score at online apply', nil)
      end
    end

    def notify_online_apply_result(contractor)
      notify_online_apply_reject(contractor) if contractor.rejected?
      notify_online_apply_complete(contractor) if contractor.processing?
    end

    def notify_online_apply_reject(contractor)
      # SMS送信
      SendMessage.reject_contractor(contractor)

      # メール送信
      SendMail.reject_contractor(contractor)

      # SSスタッフ結果(リジェクト)通知
      SendMail.scoring_results_notification_to_ss_staffs(contractor, false)
    end

    def notify_online_apply_complete(contractor)
      # SMS送信
      SendMessage.online_apply_complete(contractor)

      # メール送信
      SendMail.online_apply_complete(contractor)
    end
end
