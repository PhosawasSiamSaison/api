# frozen_string_literal: true

class OnlineApply::ApplicationController < ActionController::API
  after_action :log_response if Rails.env.development?

  rescue_from Exception, with: :catch_exception

  def log_response
    pp JSON.parse(response.body)
  end

  def catch_exception(exception)
    # DBエラーを判定させる
    if exception.to_s.include?("Mysql2::Error")
      mysql_error(exception)
    else
      system_error(exception)
    end
  end

  def system_error(exception)
    pp exception.backtrace if Rails.env.development?

    logger.fatal exception.inspect
    render json: { success: false, error: "system_error", error_detail: exception.message }
  end

  def mysql_error(exception)
    logger.info exception.inspect
    render json: { success: false, error: "validation_error", error_detail: exception.cause }
  end
end
