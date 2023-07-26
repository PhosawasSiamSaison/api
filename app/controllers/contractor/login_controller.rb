# frozen_string_literal: true

class Contractor::LoginController < ApplicationController
  def login
    contractor_user = ContractorUser.find_by(user_name: params[:user_name])

    # ログインエラー
    unless AuthContractorUser.new(contractor_user, params[:password]).call
      return render json: { success: false, errors: set_errors('error_message.login_error') }
    end

    # ログイン成功
    auth_token = contractor_user.generate_auth_token
    contractor_user.save_auth_token(auth_token)

    render json: {
      success:    true,
      auth_token: auth_token,
    }
  end

  # LINEのアカウント連携ログイン
  def auth_line
    contractor_user = ContractorUser.find_by(user_name: params[:user_name])

    # 認証エラー
    unless AuthContractorUser.new(contractor_user, params[:password]).call
      return render json: { success: false, errors: set_errors('error_message.login_error') }
    end

    # 認証成功
    link_token = params[:link_token]

    # nonce を作成する
    nonce = SecureRandom.urlsafe_base64

    # nonceをcontractor_usersに保存する。linkTokenは保存不要
    contractor_user.update!(line_nonce: nonce)

    # リダイレクトURLを返す
    render json: {
      success: true,
      redirect_url: "https://access.line.me/dialog/bot/accountLink?linkToken=#{link_token}&nonce=#{nonce}",
    }
  end

  def generate_nonce
    # 重複しない値を生成
    loop do
      random_token = SecureRandom.urlsafe_base64
      break random_token unless ContractorUser.exists?(line_nonce: random_token)
    end
  end
end
