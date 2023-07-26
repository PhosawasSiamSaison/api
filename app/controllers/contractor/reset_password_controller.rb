# frozen_string_literal: true

class Contractor::ResetPasswordController < ApplicationController
  before_action :auth_user, only: [:update_password]

  # リセットのリクエスト。トークンとurlを生成してsmsで送信する
  def reset_password
    tax_id = params[:tax_id]
    user_name = params[:user_name]

    # アカウントロック
    if PasswordResetFailedUserName.locked?(user_name)
      return render json: { success: true, result: 'locked' }
    end

    contractor = Contractor.find_by(tax_id: tax_id)
    contractor_user = contractor&.contractor_users&.find_by(user_name: user_name)

    if contractor_user.present?
      # URLに付加するauth_tokenの生成
      auth_token = contractor_user.generate_auth_token
      contractor_user.save_auth_token(auth_token)

      SendMessage.send_contractor_user_reset_password(contractor_user, auth_token)

      render json: { success: true, result: 'send_sms' }
    else
      password_reset_failed_user_name = PasswordResetFailedUserName.create!(user_name: user_name)

      if PasswordResetFailedUserName.rearched_lock_limit?(user_name)
        password_reset_failed_user_name.update!(locked: true)

        render json: { success: true, result: 'locked' }
      else
        render json: { success: true, result: 'invalid' }
      end
    end
  end

  # 上記で生成したurlから画面へ移動。一時トークンとともに新しいパスワードを受け取る
  def update_password
    login_user.password = params[:password]
    auth_token          = params[:auth_token]

    if login_user.save(context: :password_update)
      # 更新が成功したらauth_tokenを削除する
      AuthToken.find_by(token: auth_token).destroy

      # 新しいauth_tokenの生成
      new_auth_token = login_user.generate_auth_token
      login_user.save_auth_token(new_auth_token)

      render json: {
        success: true,
        new_auth_token: new_auth_token,
        user_name: login_user.user_name
      }
    else
      render json: { success: false, errors: login_user.error_messages }
    end
  end
end
