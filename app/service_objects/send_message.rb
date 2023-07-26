class SendMessage
  class << self
    # 1: パスワードリセット(リセット画面URLを送信)
    def send_contractor_user_reset_password(contractor_user, auth_token)
      type = :password_reset

      @url = "#{host_name}/initial/passcode/change?token=#{auth_token}"

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 2: コントラクター承認時のコントラクターユーザー登録の初回認証SMS(認証画面URLを送信)
    def send_register_user_on_approval(contractor_user)
      type = :register_user_on_approval

      @servcie_name = contractor_user.contractor.sms_servcie_name

      access_key = contractor_user.initialize_token
      @url = "#{host_name}/initial/personal?access_key=#{access_key}"

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 3: 初回認証成功時のSMS(ログイン情報を送信)
    def send_personal_id_confirmed(contractor_user)
      type = :personal_id_confirmed

      @user_name = contractor_user.user_name
      @temp_password = contractor_user.temp_password
      @signin_url = "#{host_name}/signin"

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 4: 開発用なので実装なし

    # 5: 約定日の2日前に、支払いがあるContractorUserに送信
    def send_reminder_two_days_before_due_date(payment, contractor_user)
      type = :reminder_two_days_before_due_date
      contractor = contractor_user.contractor

      # CashbackとExceededを減算した支払い残金を取得
      payment_remining_balance = contractor.remining_balance_with_subtraction(payment)

      # 支払い残金
      @due_amount = amount_format(payment_remining_balance)
      # due_ymdの DD / MM / YY 形式
      @due_date = format_th_date(payment.due_ymd)

      @exist_over_due_payment = contractor.payments.over_due.exists?

      @url = host_name

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 6: 約定日の当日に、支払いがあるContractorUserに送信
    def send_reminder_on_due_date(payment, contractor_user)
      type = :reminder_on_due_date
      contractor = contractor_user.contractor

      # CashbackとExceededを減算した支払い残金を取得
      payment_remining_balance = contractor.remining_balance_with_subtraction(payment)

      # 支払い残金
      @due_amount = amount_format(payment_remining_balance)
      # due_ymdの DD / MM / YY 形式
      @due_date = format_th_date(payment.due_ymd)

      @exist_over_due_payment = contractor.payments.over_due.exists?

      @url = host_name

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 7: Payment確定後(締め日の翌日)、支払額の通知
    def send_inform_statement(payment, contractor_user)
      type = :inform_statement
      contractor = contractor_user.contractor

      # CashbackとExceededを減算した支払い残金を取得
      payment_remining_balance = contractor.remining_balance_with_subtraction(payment)

      # 支払い残金
      @due_amount = amount_format(payment_remining_balance)
      # due_ymdの DD / MM / YY 形式
      @due_date = format_th_date(payment.due_ymd)

      @signin_url = "#{host_name}/signin"

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 8: 支払いが遅延しているContractorに送る
    def send_over_due_next_day(contractor_user)
      type = :over_due_next_day
      contractor = contractor_user.contractor

      # 遅延しているPaymentの支払い残金の合計(cashbackとexceededを減算して計算)
      @over_due_amount = amount_format(contractor.calc_over_due_amount)

      @url = host_name

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 9: RUDYで商品購入トークンを取得するためのパスコードを送信する
    def send_one_time_passcode(contractor_user, passcode)
      type = :send_one_time_passcode

      @passcode = passcode

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 10: ローン変更申請の承認・否認の確定後に送信
    def send_approval_change_product(contractor_user)
      type = :approval_change_product

      @signin_url = "#{host_name}/signin"

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 11: 約定日の１週間前にローン変更申請可能通知を送る
    # メモ:B2BとCPAC-SOLのみで送信想定なので一部を固定値で使用(service_nameなど)
    def send_can_switch_7days_ago(body_data, contractor_user)
      type = :can_switch_7days_ago_sms

      @amount = amount_format(body_data[:total_due_amount])
      @switch_sms_product_names = body_data[:switch_sms_product_names]
      @url = host_name
      @line_account = body_data[:line_account]

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 12: サイト情報の通知
    def send_new_site_information(contractor_user, site_information)
      type = :new_site_information

      @url               = site_information[:url]
      @site_code         = site_information[:site_code]
      @site_credit_limit = amount_format(site_information[:site_credit_limit])
      @servcie_name      = site_information[:servcie_name]

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 13: サイト更新情報の通知
    def send_update_site_information(contractor_user, site_information)
      type = :update_site_information

      @servcie_name = site_information[:servcie_name]
      @site_code = site_information[:site_code]
      @current_site_credit_limit  = amount_format(site_information[:current_site_credit_limit])
      @adjusted_site_credit_limit = amount_format(site_information[:adjusted_site_credit_limit])
      @url = site_information[:url]

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 14: CPACオーダー登録の通知
    def send_create_cpac_order(contractor_user, site, order)
      type = :create_cpac_order

      dealer_type_setting = order.dealer.dealer_type_setting
      @servcie_name           = dealer_type_setting.sms_servcie_name
      @order_input_date       = format_th_date(order.input_ymd)
      @site_code              = site.site_code
      @site_credit_limit      = amount_format(site.site_credit_limit)
      @order_purchase_amount  = amount_format(order.purchase_amount)
      @site_available_balance = amount_format(site.available_balance)
      @signin_url             = "#{host_name}/signin"
      @contact_info           = dealer_type_setting.sms_contact_info

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 15: 約定日の3営業日前にローン変更申請可能通知を送る
    # メモ:B2BとCPAC-SOLのみで送信想定なので一部を固定値で使用(service_nameなど)
    def send_can_switch_3days_ago(body_data, due_ymd, contractor_user)
      type = :can_switch_3days_ago_sms

      @amount = amount_format(body_data[:total_due_amount])
      @switch_sms_product_names = body_data[:switch_sms_product_names]
      @due_date = format_th_date(due_ymd)
      @url = host_name
      @line_account = body_data[:line_account]

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 16: コントラクターユーザー作成時の初回認証SMS(認証画面URLを送信)
    def send_create_contractor_user(contractor_user)
      type = :create_contractor_user

      @servcie_name = contractor_user.contractor.sms_servcie_name

      access_key = contractor_user.initialize_token
      @url = "#{host_name}/initial/personal?access_key=#{access_key}"

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 17: Project情報の通知
    def send_new_project_information(contractor_user, site_information)
      type = :new_project_information

      @url               = site_information[:url]
      @site_code         = site_information[:site_code]
      @site_credit_limit = amount_format(site_information[:site_credit_limit])
      @servcie_name      = site_information[:servcie_name]

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 18: Project更新情報の通知
    def send_update_project_information(contractor_user, site_information)
      type = :update_project_information

      @servcie_name = site_information[:servcie_name]
      @site_code = site_information[:site_code]
      @current_site_credit_limit  = amount_format(site_information[:current_site_credit_limit])
      @adjusted_site_credit_limit = amount_format(site_information[:adjusted_site_credit_limit])
      @url = site_information[:url]

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 19: RUDY中継メッセージ
    def send_external_message_from_rudy(contractor_user, message)
      type = :external_message_from_rudy

      @message = message

      body = generate_message_body('external_message')

      send_message(contractor_user, body, type)
    end

    # 20: SSA中継メッセージ
    def send_external_message_from_ssa(contractor_user, message)
      type = :external_message_from_ssa

      @message = message

      body = generate_message_body('external_message')

      send_message(contractor_user, body, type)
    end

    # 21: オンライン申請のOTP(資料番号: 18)
    def send_online_apply_one_time_passcode(mobile_number, passcode)
      type = :online_apply_one_time_passcode

      @passcode = passcode

      body = generate_message_body(type)

      send_message(nil, body, type, mobile_number: mobile_number)
    end

    # 22: オンライン申請のeKYCへのリンク(資料番号: 19)
    def send_identity_verification_link(contractor)
      type = :identity_verification_link

      mobile_number = contractor.owner_mobile_number
      auth_token = contractor.online_apply_token

      page_url = JvService::Application.config.try(:online_apply_identity_verification_url)
      uri = URI(page_url)
      uri.query = { auth_token: auth_token }.to_param

      @url = uri.to_s

      body = generate_message_body(type)

      send_message(nil, body, type, mobile_number: mobile_number)
    end

    # 23: Contractor否認
    def reject_contractor(contractor)
      type = :reject_contractor

      body = generate_message_body(type)

      build_contractor_users(contractor).each do |contractor_user|
        mobile_number = contractor_user.mobile_number

        send_message(nil, body, type, mobile_number: mobile_number)
      end
    end

    # 24: PDPA同意
    def pdpa_agree(contractor_user)
      type = :pdpa_agree

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 25: RUDYへのログイン
    def login_to_rudy(contractor_user)
      type = :login_to_rudy

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 26: Online apply完了
    def online_apply_complete(contractor)
      type = :online_apply_complete

      @application_number = contractor.application_number

      body = generate_message_body(type)

      build_contractor_owners(contractor).each do |contractor_user|
        mobile_number = contractor_user.mobile_number

        send_message(nil, body, type, mobile_number: mobile_number)
      end
    end

    # 27: change_user_verify_mode_otp
    def change_user_verify_mode_otp(contractor_user, otp)
      type = :change_user_verify_mode_otp

      @otp = otp

      body = generate_message_body(type)

      send_message(contractor_user, body, type)
    end

    # 28: set_pf_site_limit
    def set_pf_site_limit(contractor, site_information)
      type = :set_pf_site_limit

      @url                        = site_information[:url]
      @site_code                  = site_information[:site_code]
      @current_site_credit_limit  = amount_format(site_information[:current_site_credit_limit])
      @adjusted_site_credit_limit = amount_format(site_information[:adjusted_site_credit_limit])
      @servcie_name               = site_information[:servcie_name]

      body = generate_message_body(type)

      contractor.contractor_users.each do |contractor_user|
        send_message(contractor_user, body, type)
      end
    end

    # 29: 入金処理（消し込み）の実行完了
    def receive_payment(contractor, payment_ymd, payment_amount)
      type = :receive_payment

      @th_company_name = contractor.th_company_name
      @receive_amount = amount_format(payment_amount)
      @received_date_thai_format = BusinessDay.th_month_format_date(payment_ymd)

      body = generate_message_body(type)

      contractor.contractor_users.each do |contractor_user|
        send_message(contractor_user, body, type)
      end
    end


    private
    def send_message(contractor_user, body, type, mobile_number: nil)
      if send_sms?(contractor_user, type)
        SmsSpool.create_and_send_sms(contractor_user, body, type, mobile_number)
      end

      if send_line?(contractor_user, type)
        LineSpool.create_and_send_line(contractor_user, body, type)
      end
    end

    # SMSで送る場合の判定
    def send_sms?(contractor_user, type)
      return true if contractor_user.nil?

      # LINEで送らないSMSの場合(No.2,3,16)
      return true if send_only_sms?(type)

      # LINEで送りたいがidがない場合
      return true if !contractor_user.is_linked_line_account?

      # OverDueを持っている場合
      return true if contractor_user.contractor.payments.over_due.exists?

      return false
    end

    # LINEで送る場合の判定
    def send_line?(contractor_user, type)
      # LINE IDを持っているかつ、LINEで送れるtypeの場合
      contractor_user&.is_linked_line_account? && can_send_line?(type)
    end

    # SMSでのみ送るtype判定
    def send_only_sms?(type)
      [
        :register_user_on_approval, # No.2
        :personal_id_confirmed, # No.3
        :create_contractor_user, # No.16
      ].include?(type)
    end

    # LINEで送れるtype判定
    def can_send_line?(type)
      # SMSでのみ送るtype以外
      !send_only_sms?(type)
    end

    def amount_format(amount)
      amount.to_s(:delimited)
    end

    def host_name
      JvService::Application.config.try(:frontend_host_name)
    end

    # テンプレートから内容を生成する
    def generate_message_body(type)
      template = Rails.root.join('app/views/messages', "#{type}.text.erb")
      ERB.new(File.open(template).read, nil, '-').result(binding)
    end

    # タイの日付形式へ変換
    def format_th_date ymd
      Date.parse(ymd).strftime('%d / %m / %Y')
    end

    # Contractor情報から取得したContractorUserのリスト
    def build_contractor_users(contractor)
      BuildContractorUsers.new(contractor, nil).call
    end

    def build_contractor_owners(contractor)
      build_contractor_users(contractor).select { |contractor_user| contractor_user.user_type == 'owner' }
    end
  end
end
