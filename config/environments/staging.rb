Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :amazon

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV['JV_LOG_LEVEL']

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  config.active_job.queue_adapter = :sidekiq
  # config.active_job.queue_name_prefix = "jv_service_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = true

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')
  config.logger = Logger.new("log/production.log", 'daily')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session


  config.time_zone = 'Bangkok'
  config.active_record.default_timezone = :local


  # RUDY ホスト
  config.rudy_host = ENV['JV_RUDY_HOST']

  # RUDY テスト用のパラメーターでリクエストをする
  config.rudy_use_test_params = ENV['JV_USE_RUDY_TEST_PARAM'].present?

  # RUDY RUDYからのリクエスト用のAPIのBearerのキー
  config.rudy_api_auth_key = ENV['JV_RUDY_API_AUTH_KEY']
  config.rudy_demo_api_auth_key = 'dm1riodl4wfwkcy2t1cd6aoiec51f9hr00gbwog3ip2rkork2501u60785xhup75'

  # Creden ホスト
  config.creden_use_mock = ENV['JV_CREDEN_USE_MOCK'] == 'true'
  config.creden_host = ENV['JV_CREDEN_HOST']
  config.creden_api_key = ENV['JV_CREDEN_API_KEY']

  # SSAからのリクエスト用のAPIのBearerのキー
  config.ssa_api_auth_key = ENV['JV_SSA_API_AUTH_KEY']

  # SS画面のホスト名
  config.ss_frontend_host_name = ENV['JV_WEB_JV_URL']

  # C画面のホスト名
  config.frontend_host_name = ENV['JV_WEB_C_URL']

  # SMS送信の際に指定する国番号(日本: +81, タイ; +66)
  config.country_code = ENV['JV_SNS_COUNTRY_CODE']

  # SMS送信フラグ
  config.send_sms = true

  # AWSのSMS制限を回避する
  config.delay_batch_send_sms = true

  # SMSを送信しない電話番号
  config.not_send_mobile_numbers = ['9999999999','8888888888','7777777777','6666666666','5555555555']


  # AWS
  config.aws_access_key_id     = ''
  config.aws_secret_access_key = ''
  config.aws_region = ENV['JV_AWS_REGION']
  config.aws_bucket = ENV['JV_AWS_S3_BUCKET']


  # ThaiBulkSMS
  config.thai_bulk_sms_use_mock_response = false
  config.thai_bulk_sms_api_key = ENV['JV_THAIBULK_API_KEY']
  config.thai_bulk_sms_api_secret = ENV['JV_THAIBULK_API_SECRET']


  # LINE Bot アカウント
  config.line_bot_basic_id = ENV['JV_LINE_BOT_BASIC_ID']
  config.line_bot_channel_secret = ENV['JV_LINE_BOT_CHANNEL_SECRET']
  config.line_bot_channel_token = ENV['JV_LINE_BOT_CHANNEL_TOKEN']
  config.line_link_account_word = ENV['JV_LINE_LINK_ACCOUNT_WORD']
  config.send_line = true # productionは常にtrue


  # Email
  ## 送信者（標準）
  config.mail_sender_name    = ENV['JV_MAIL_SENDER_NAME'] # 送信者の名前
  config.mail_sender_address = ENV['JV_MAIL_SENDER_ADDRESS'] # 送信者のアドレス
  ## SMTP設定（標準）
  config.smtp_user_name      = ENV['JV_SMTP_USER_NAME']
  config.smtp_password       = ENV['JV_SMTP_PASSWORD']

  ## 送信者（PDPA）
  config.mail_sender_name_pdpa    = ENV['JV_MAIL_SENDER_NAME_PDPA']
  config.mail_sender_address_pdpa = ENV['JV_MAIL_SENDER_ADDRESS_PDPA']
  ## SMTP設定（PDPA）
  config.smtp_user_name_pdpa      = ENV['JV_SMTP_USER_NAME_PDPA']
  config.smtp_password_pdpa       = ENV['JV_SMTP_PASSWORD_PDPA']

  config.send_mail = ENV['JV_SEND_EMAIL'] == "true"
  # SSスタッフ向けアドレスの設定(カンマ区切りで複数設定可能)
  config.ss_staffs_email_address = ENV['JV_SS_STAFF_EMAIL_ADDRESSES'] || ''
  # Exceeded payment notification メールの宛先(カンマ区切りで複数設定可能)
  config.ss_staffs_collection_email_address = ENV['JV_SS_STAFF_COLLECTION_EMAIL_ADDRESSES'] || ''

  config.action_mailer.smtp_settings = {
    delivery_method:      :smtp,
    port:                 587,
    address:              ENV['JV_SMTP_ADDRESS'],
    domain:               ENV['JV_SMTP_DOMAIN'],
    user_name:            nil, # コード内で分岐して smtp_user_name から取得
    password:             nil, # コード内で分岐して smtp_password から取得
    authentication:       'login',
    enable_starttls_auto: true
  }

  # config.action_mailer.smtp_settings = {
  #   :delivery_method      => :smtp,
  #   :address              => "smtp.office365.com",
  #   :port                 => 587,
  #   :user_name            => ENV["MAIL_USER_NAME"],
  #   :password             => ENV["MAIL_PASSWORD"],
  #   :authentication       => "login",
  #   :enable_starttls_auto => true,
  #   :enable_starttls      => true
  # }


  # online_apply Email/電話番号の確認
  config.online_apply_validate_address_limit_minutes = ENV['JV_AP_VALIDATE_ADDRESS_LIMIT_MINUTES'] || 15

  # オンライン申し込み本人確認画像アップロード画面URL
  config.online_apply_identity_verification_url = ENV['JV_AP_IDENTITY_VERIFICATION_URL']

  # オンライン申請で Use Only Credit Limit をオフにするフラグ
  config.no_use_only_credit_limit = ENV['JV_NO_USE_ONLY_CREDIT_LIMIT'] == "true"

  # RUDYからの自動入金処理の許可
  config.enable_rudy_confirm_payment = ENV['JV_ENABLE_RUDY_CONFIRM_PAYMENT'] == "true"

  # レポートCSV出力完了後にシステムコマンド実行するファイルのパス
  config.after_reporting_script_path = ENV['JV_AFTER_REPORTING_SCRIPT_PATH']

  # Exceeded/Cashbackの自動消し込み設定
  config.auto_repayment_exceeded_and_cashback = ENV['JV_AUTO_REPAYMENT_EXCEEDED_AND_CASHBACK'] == "true"
end
