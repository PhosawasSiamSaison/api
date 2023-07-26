# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = false
  config.action_view.cache_template_loading = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true


  # RUDY テスト用のパラメーターでリクエストをする
  config.rudy_use_test_params = false
  # RUDY RUDYからのリクエスト用のAPIのBearerのキー
  config.rudy_api_auth_key = 'test_rudy'
  # RUDY (デモ用)RUDYからのリクエスト用のAPIのBearerのキー
  config.rudy_demo_api_auth_key = 'demo_token'
  # RUDY ログイン用のホスト
  config.rudy_login_host = ''

  # SSAからのリクエスト用のAPIのBearerのキー
  config.ssa_api_auth_key = 'test_ssa'

  # SS画面のホスト名
  config.ss_frontend_host_name = ENV['JV_WEB_JV_URL'] || 'http://localhost:3002'

  # C画面のホスト名
  config.frontend_host_name = ENV['JV_WEB_C_URL'] || 'http://localhost:3003'

  # SMS送信
  config.send_sms = false
  # AWSのSMS制限を回避する
  config.delay_batch_send_sms = false
  # SMSを送信しない電話番号
  config.not_send_mobile_numbers = ['999']
  # SMS送信の際に指定する国番号(日本: +81, タイ; +66)
  config.country_code = '+81'

  # ThaiBulkSMS
  config.thai_bulk_sms_use_mock_response = true
  config.thai_bulk_sms_api_key = ""
  config.thai_bulk_sms_api_secret = ""

  # LINE
  config.send_line = false

  # Email
  ## 送信者（標準）
  config.mail_sender_name = ''
  config.mail_sender_address = ''
  ## 送信者（PDPA）
  config.mail_sender_name_pdpa = ''
  config.mail_sender_address_pdpa = ''

  config.send_mail = false
  # SSスタッフ向けアドレスの設定(カンマ区切りで複数設定可能)
  config.ss_staffs_email_address = ''
  # Exceeded payment notification メールの宛先(カンマ区切りで複数設定可能)
  config.ss_staffs_collection_email_address = 'a@a.com' # mail_spoolを作成するために適当な値を設定

  config.action_mailer.smtp_settings = {
    delivery_method: :test
  }

  # online_apply Email/電話番号の確認
  config.online_apply_validate_address_limit_minutes = ENV['AP_VALIDATE_ADDRESS_LIMIT_MINUTES'] || 15

  # オンライン申し込み本人確認画像アップロード画面URL
  config.online_apply_identity_verification_url = ''

  # オンライン申請で Use Only Credit Limit をオフにするフラグ
  config.no_use_only_credit_limit = ENV['JV_NO_USE_ONLY_CREDIT_LIMIT'] == "true"

  # RUDYからの自動入金処理の許可
  config.enable_rudy_confirm_payment = true
end
