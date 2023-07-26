# frozen_string_literal: true

class Contractor::PdpaAgreementController < ApplicationController
  before_action :auth_user

  def pdpa_agreement_status
    latest_pdpa_version = PdpaVersion.all.latest

    render json: {
      success: true,
      file_url: latest_pdpa_version.file_url,
      version: latest_pdpa_version.version,
    }
  end

  def submit_pdpa_agreement
    pdpa_version = PdpaVersion.find_by(version: params.fetch(:version))

    # 画面で規約が更新されていた場合はリロードさせる
    raise UnmatchFrontVersion unless pdpa_version.latest?

    # 同意レコードの作成
    login_user.create_latest_pdpa_agreement!

    # ContractorUser宛メール
    SendMail.pdpa_agree(login_user) if login_user.email.present?
    # ContractorUser宛メッセージ
    SendMessage.pdpa_agree(login_user)

    # スタッフ向けメール
    SendMail.pdpa_notification_to_ss_staffs(login_user)

    render json: {
      success: true,
    }
  rescue ActiveRecord::RecordNotUnique => e
    raise ActiveRecord::StaleObjectError
  end
end