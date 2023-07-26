# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += ['@stream']

if Rails.env.production?
  Rails.application.config.filter_parameters += ['password', 'passcode', 'payment_image', 'data', 'qr_code_image']
end

