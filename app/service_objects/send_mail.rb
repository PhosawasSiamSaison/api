class SendMail
  class << self
    # 1: オンライン申請のOTP
    def send_online_apply_one_time_passcode(email, passcode, applicant_name)
      mail_type = :online_apply_one_time_passcode_mail

      @applicant_name = applicant_name
      @passcode = passcode

      subject = 'รหัสผ่าน OTP สำหรับสมัครสินเชื่อเซย์ซอนเครดิต'
      mail_body = generate_message_body(mail_type)

      MailSpool.create_and_send_mail(subject, mail_body, mail_type, email: email)
    end

    # 2: Contrator承認
    def approve_contractor(contractor)
      mail_type = :approve_contractor

      @th_company_name = contractor.th_company_name

      subject = 'แจ้งการเปิดใช้บริการสินเชื่อเซย์ซอนเครดิต'
      mail_body = generate_message_body(mail_type)

      build_contractor_users(contractor).each do |contractor_user|
        email = contractor_user.email

        MailSpool.create_and_send_mail(subject, mail_body, mail_type, contractor: contractor, email: email)
      end
    end

    # 3: Contrator否認
    def reject_contractor(contractor)
      mail_type = :reject_contractor

      subject = 'แจ้งผลการสมัครสินเชื่อ Saison Credit'

      build_contractor_users(contractor).each do |contractor_user|
        @th_name = contractor_user.full_name

        mail_body = generate_message_body(mail_type)

        MailSpool.create_and_send_mail(subject, mail_body, mail_type, contractor: contractor, email: contractor_user.email)
      end
    end

    # 4: 審査結果SSスタッフ通知
    def scoring_results_notification_to_ss_staffs(contractor, approval)
      mail_type = :scoring_results_to_staff

      @contractor = contractor

      @dealers = contractor.latest_dealer_limits.map.with_index(1) do |dealer_limit, i|
        dealer = dealer_limit.dealer

        {
          i: i,
          th_name: dealer.dealer_name,
          en_name: dealer.en_dealer_name || '-',
          credit_limit: amount_format(dealer_limit.limit_amount)
        }
      end

      @result = approval ? 'Approval' : 'Reject'
      @result_date = format_th_date(contractor.approved_at || contractor.rejected_at)

      # リンクURL
      front_page = approval ? "contractors/contractor" : "processing/contractors/contractor"
      page_url = URI.join(ss_host_name, front_page)
      uri = URI(page_url)
      uri.query = { id: contractor.id }.to_param

      @url = uri.to_s

      subject = 'Scoring result'
      mail_body = generate_message_body(mail_type)

      ss_staffs_email_address.each do |email|
        MailSpool.create_and_send_mail(subject, mail_body, mail_type, email: email)
      end
    end

    # 5: PDPA合意
    def pdpa_agree(contractor_user)
      mail_type = :pdpa_agree

      subject = 'แจ้งรายละเอียดการยินยอมให้บริษัทฯ เก็บรวบรวม ใช้ และเปิดเผยข้อมูลส่วนบุคคลของ'

      @th_name = contractor_user.full_name

      mail_body = generate_message_body(mail_type)

      MailSpool.create_and_send_mail(subject, mail_body, mail_type, contractor_user: contractor_user)
    end

    # 6: PDPA結果通知
    def pdpa_notification_to_ss_staffs(contractor_user)
      mail_type = :pdpa_results_to_staff

      subject = 'PDPA T&C update'

      @contractor_user = contractor_user
      @contractor = contractor_user.contractor

      @agreed_at = format_th_date(contractor_user.agreed_contractor_user_pdpa_versions.latest_agreed_at)
      @url = ss_contractor_users_url(contractor_user.contractor.id)

      mail_body = generate_message_body(mail_type)

      ss_staffs_email_address.each do |email|
        MailSpool.create_and_send_mail(subject, mail_body, mail_type, email: email)
      end
    end

    # 7: Online apply完了
    def online_apply_complete(contractor)
      mail_type = :online_apply_complete

      subject = 'แจ้งการสมัครเสร็จสมบูรณ์'

      @application_number = contractor.application_number

      build_contractor_owners(contractor).each do |contractor_user|
        @applicant_name = contractor_user.full_name

        mail_body = generate_message_body(mail_type)

        email = contractor_user.email
        MailSpool.create_and_send_mail(subject, mail_body, mail_type, contractor: contractor, email: email)
      end
    end

    # 8: Billing PDFの送付
    def contractor_billing_pdf(contractor_billing_data)
      mail_type = :contractor_billing_pdf

      contractor = contractor_billing_data.contractor

      th_date = BusinessDay.th_month_format_date(contractor_billing_data.due_ymd)

      subject = "ใบแจ้งยอดรายการเซย์ซอนเครดิต (ครบกำหนดชำระ #{th_date})"

      @th_company_name = contractor.th_company_name
      @due_date_thai_format = th_date
      @contact_info = billing_pdf_contact_info(contractor)

      mail_body = generate_message_body(mail_type)

      MailSpool.create_and_send_mail(
        subject,
        mail_body,
        mail_type,
        contractor: contractor,
        contractor_users: contractor.contractor_users,
        contractor_billing_data: contractor_billing_data
      )
    end

    # 9: 入金処理（消し込み）の実行完了
    def receive_payment(contractor, payment_ymd, payment_amount)
      mail_type = :receive_payment
      subject = 'แจ้งการได้รับเงิน'

      @th_company_name = contractor.th_company_name
      @receive_amount = amount_format(payment_amount)
      @received_date_thai_format = BusinessDay.th_month_format_date(payment_ymd)

      mail_body = generate_message_body(mail_type)

      MailSpool.create_and_send_mail(
        subject, mail_body, mail_type, contractor: contractor, contractor_users: contractor.contractor_users
      )
    end

    # 10: 自動入金処理（RUDYからの消し込み）で Exceededが発生。スタッフ宛
    def exceeded_payment(contractor, receive_amount_history)
      mail_type = :exceeded_payment
      subject = 'Exceeded payment notification'

      # 消し込まれたPaymentのdue_dateを取得
      due_dates = receive_amount_history.receive_amount_details.map{|row|
        format_th_date(row.payment&.due_ymd)
      }.uniq.join(', ') # installments単位で取得されるので重複を削除する

      # 消し込まれたOrderのorder_numberを取得
      order_numbers = receive_amount_history.receive_amount_details.map{|row| row.order&.order_number}.join(', ')

      @en_company_name = contractor.en_company_name
      @due_dates       = due_dates
      @order_numbers   = order_numbers
      @receive_amount  = amount_format(receive_amount_history.receive_amount)
      @receive_date    = format_th_date(receive_amount_history.receive_ymd)
      @operate_date    = format_th_date(receive_amount_history.created_at)
      @exceeded_amount = amount_format(receive_amount_history.exceeded_occurred_amount)
      @url             = ss_repayment_history_url(contractor.tax_id)

      mail_body = generate_message_body(mail_type)

      ss_staffs_collection_email_address.each do |email|
        MailSpool.create_and_send_mail(subject, mail_body, mail_type, email: email)
      end
    end

    # 99: 開発用
    def test_mail(email, subject, message)
      mail_type = :test_mail

      @msg = message

      mail_body = generate_message_body(mail_type)

      MailSpool.create_and_send_mail(nil, subject, mail_body, mail_type, email: email)
    end

    private
      # テンプレートから内容を生成する
      def generate_message_body(type)
        template = Rails.root.join('app/views/jv_mailer', "#{type}.text.erb")
        ERB.new(File.open(template).read, nil, '-').result(binding)
      end

      # SSスタッフのメールリスト
      def ss_staffs_email_address
        JvService::Application.config.try(:ss_staffs_email_address).split(',')
      end

      def ss_staffs_collection_email_address
        JvService::Application.config.try(:ss_staffs_collection_email_address).split(',')
      end

      # Contractor情報から取得したContractorUserのリスト
      def build_contractor_users(contractor)
        BuildContractorUsers.new(contractor, nil).call
      end

      def build_contractor_owners(contractor)
        build_contractor_users(contractor).select { |contractor_user| contractor_user.user_type == 'owner' }
      end

      def amount_format amount
        amount.to_s(:delimited)
      end

      def ss_host_name
        JvService::Application.config.try(:ss_frontend_host_name)
      end

      # タイの日付形式へ変換
      def format_th_date date
        return nil if date.blank?

        date.is_a?(String) ? Date.parse(date).strftime(th_ymd_format) : date.strftime(th_ymd_format)
      end

      def th_ymd_format
        '%d / %m / %Y'
      end

      def format_th_pdf_ymd(ymd)
        GenerateContractorBillingPDF.new.th_date(ymd)
      end

      def ss_contractor_users_url(contractor_id)
        page_url = URI.join(ss_host_name, "contractors/contractor/users")
        uri = URI(page_url)
        uri.query = { id: contractor_id }.to_param
        uri.to_s
      end

      def ss_repayment_history_url(tax_id)
        add_params('repayments/history', { tax_id: tax_id })
      end

      def add_params(path, params)
        page_url = URI.join(ss_host_name, path)
        uri = URI(page_url)
        uri.query = params.to_param
        uri.to_s
      end

      def billing_pdf_contact_info(contractor)
        if contractor.sub_dealer? || contractor.individual?
          "@saison_subdealer"
        elsif contractor.main_dealer&.cpac?
          "@cpacsmilecredit"
        elsif contractor.main_dealer&.q_mix?
          "@qmixsaison"
        else
          "@siamsaison"
        end
      end
  end
end
