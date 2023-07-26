module ErrorInfoModule
  def set_errors error_name
    Rails.logger.info "ValidationError, Locale Path: #{error_name}"

    [I18n.t(error_name)]
  end

  # 権限を判定して、権限がなければエラーを返す
  def check_permission_errors(permission_ok)
    permission_ok ? nil : set_errors('error_message.permission_denied')
  end
end