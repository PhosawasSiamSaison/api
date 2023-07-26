# frozen_string_literal: true

module Formatter
  # レスポンスを使いやすいように整形
  def res
    JSON.parse(response.body).deep_symbolize_keys
  end
end
