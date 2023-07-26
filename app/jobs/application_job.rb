class ApplicationJob < ActiveJob::Base
  rescue_from(StandardError) do |e|
    log_info("Failed to send sms. Error:#{e.message}")
  end

  private

  def log_info(message)
    logger.info "[#{self.class.name}] Message: #{message}"
  end
end
