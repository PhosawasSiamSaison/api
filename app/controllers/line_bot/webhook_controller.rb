# frozen_string_literal: true

# プロバイダーbotサーバーに見立てたコントローラー
class LineBot::WebhookController < ActionController::API
  require 'line/bot'

  def call
    log_start(params)

    # LINE以外からのアクセスを許可しない
    raise 'Access Denied' unless valid_signature?

    # 複数ある場合はループする
    params["events"].each do |event|
      # イベントの分岐
      case event["type"]
      when "message"
        event_message(event)

      when "accountLink"
        event_account_link(event)

      when 'unfollow'
        event_unfollow(event)

      else
         p "else event type: #{event["type"]}"
      end
    end

    render json: { status: 200 }
  end

  private

  def line_client
    @line_client ||= LineBotClient.new
  end

  # ユーザーがメッセージを送信時のイベント
  def event_message(event)
    user_id = event["source"]["userId"]

    if event["message"]["text"] == JvService::Application.config.try(:line_link_account_word)
      # LINE APIにLinkTokenを要請
      res = line_client.create_link_token(user_id)
      linkToken = JSON.parse(res.body)["linkToken"]

      # フロントのエンドポイントを取得
      front_endpoint = JvService::Application.config.try(:frontend_host_name)
      # 連携URL
      account_link_url = URI.join(front_endpoint, "/link_line_account?linkToken=#{linkToken}")

      # テンプレートメッセージを作成
      message = gen_account_link_message(account_link_url)

      # ユーザーに連携URLを送る
      line_client.push_message(user_id, message)
    else
      p "else message text: #{event["message"]["text"]}"
    end
  end

  # アカウント連携完了時のイベント
  def event_account_link(event)
    if event["link"]["result"] == "ok"
      nonce = event["link"]["nonce"]
      user_id = event["source"]["userId"]

      # ContractorUserの更新
      ContractorUser.find_by(line_nonce: nonce).update!(line_user_id: user_id)

      # ユーザーに完了メッセージを送る
      reply_token = event["replyToken"]
      # TODO 必要があれば送る
      # res = line_client.reply_message(reply_token, "連携が完了しました。")
    else
      p "失敗"
    end
  end

  # ユーザーがアカウントをブロック
  def event_unfollow(event)
    user_id = event["source"]["userId"]

    contractor_user = ContractorUser.find_by(line_user_id: user_id)

    # アカウント連携を解除
    contractor_user&.update!(line_user_id: nil, line_nonce: nil)
  end

  private
  def gen_account_link_message(account_link_url)
    text = "บริษัท สยาม เซย์ซอน จำกัด"
    alttext = "กดเพื่อยืนยันการเชื่อมต่อกับบัญชีไลน์"

    action = {
      "type": "uri",
      "label": "กดปุ่มนี้เพื่อเชื่อมต่อ",
      "uri": account_link_url
    }

    return [{
      "type": "template",
      "altText": alttext,
      "template": {
        "type": "buttons",
        "thumbnailImageUrl": account_link_image_common_index_url,
        "imageAspectRatio": "rectangle",
        "imageSize": "cover",
        "imageBackgroundColor": "#FFFFFF",
        "text": text,
        "defaultAction": action,
        "actions": [action]
      }
    }]
  end

  def log_start(params)
    Rails.logger.info({
      "logtype": "LINE-WEBHOOK-REQUEST",
      "params": params,
    }.to_json)
  end

  def valid_signature?
    # 開発時は検証しない
    return true unless Rails.env.production?

    channel_secret = JvService::Application.config.try(:line_bot_channel_secret)
    http_request_body = request.raw_post # Request body string
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, channel_secret, http_request_body)
    signature = Base64.strict_encode64(hash)

    request.headers["x-line-signature"] == signature
  end
end
