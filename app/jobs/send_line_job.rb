class SendLineJob < ApplicationJob
  queue_as :default
  # TODO:エラーが発生するケースを調べてリトライ制御の導入を検討する
  # retry_on(*exceptions, wait: 3.seconds, attempts: 5, queue: nil, priority: nil)

  def perform(line)
    messages = {
      type: 'text',
      text: line.message_body
    }

    res = LineBotClient.new.push_message(line.send_to, messages)

    if res.message == 'OK'
      line.done!
    else
      line.failed!
    end
  end
end
