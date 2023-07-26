unless Rails.env.development?
  class ActionDispatch::DebugExceptions
    alias_method :org_log_error, :log_error

    def log_error(request, wrapper)
      if wrapper.exception.is_a? ActionController::RoutingError
        Rails.logger.error wrapper.exception.message
      else
        org_log_error request, wrapper
      end
    end
  end
end