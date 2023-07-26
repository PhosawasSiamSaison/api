# frozen_string_literal: true

# ContractorDetailController を継承
class Jv::ProcessingDetailController < Jv::ContractorDetailController
  def approve_contractor
    contractor = Contractor.find(params[:contractor_id])

    # Credit Limit が未登録ならエラー
    if contractor.eligibilities.blank?
      return render json: {
        success: false,
        errors: [I18n.t("error_message.credit_limit_not_registered")]
      }
    end

    errors = ApprovalContractor.new(contractor, login_user).call

    if errors.nil?
      # 承認メールの送信
      SendMail.approve_contractor(contractor)

      # SSスタッフ結果通知
      send_email_for_staff contractor, true

      render json: { success: true }
    else
      render json: { success: false, errors: errors }
    end
  end

  def reject_contractor
    contractor_id = params[:contractor_id]
    send_sms_flg = params[:send_sms]

    contractor = Contractor.find(contractor_id)

    # リジェクト処理
    RejectContractor.new(contractor, login_user).call

    if send_sms_flg
      # SMS送信
      SendMessage.reject_contractor(contractor)

      # メール送信
      SendMail.reject_contractor(contractor)
    end

    # SSスタッフ結果通知
    send_email_for_staff contractor, false

    render json: { success: true }
  end

  # 作成予定の contractor_users の取得
  def contractor_users
    contractor = Contractor.find(params[:contractor_id])

    contractor_users = BuildContractorUsers.new(contractor, login_user).call

    contractor_users = contractor_users.map do |contractor_user|
      {
        full_name:      contractor_user.full_name,
        user_name:      contractor_user.user_name,
        user_type:      contractor_user.user_type_label,
        title_division: contractor_user.title_division,
        mobile_number:  contractor_user.mobile_number,
        email:          contractor_user.email,
      }
    end

    render json: { success: true, contractor_users: contractor_users }
  end

  private
    # SSスタッフ結果通知
    def send_email_for_staff contractor, result
      SendMail.scoring_results_notification_to_ss_staffs(contractor, result)
    end
end
