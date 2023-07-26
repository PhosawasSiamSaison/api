# Line::Bot::Client のラッパークラス
class LineBotClient
  def initialize
    client
  end

  def create_link_token(user_id)
    log_start("create_link_token", { user_id: user_id })

    res = client.create_link_token(user_id)

    log_finish("create_link_token", res)

    return res
  end

  def push_message(user_id, messages)
    log_start("push_message", { user_id: user_id, messages: messages })

    res = client.push_message(user_id, messages)

    log_finish("push_message", res)

    return res
  end

  def push_text_message(user_id, message)
    messages = {
      type: 'text',
      text: message
    }

    push_message(user_id, messages)
  end

  def reply_message(reply_token, message)
    log_start("reply_message", { reply_token: reply_token, message: message })

    res = client.reply_message(reply_token, message)

    log_finish("reply_message", res)

    return res
  end

  private
  def client
    @line_client ||= Line::Bot::Client.new { |config|
      config.channel_secret = JvService::Application.config.try(:line_bot_channel_secret)
      config.channel_token = JvService::Application.config.try(:line_bot_channel_token)
    }
  end

  def log_start(action, params)
    Rails.logger.info({
      "logtype": "LINE-API-REQUEST",
      "action": action,
      "params": params,
    }.to_json)
  end

  def log_finish(action, res)
    Rails.logger.info({
      "logtype": "LINE-API-RESPONSE",
      "action": action,
      "response": JSON.parse(res.body),
    }.to_json)
  end
end
