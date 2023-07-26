desc 'DBをmaskする。引数に入力したパスワードが全てのContractor/Dealer/JV Userのパスワードとして設定される。引数が無い場合は、パスワードは102310に設定される'
task :mask_data, ['password'] => :environment do |task, args|
  puts(
  '--------------------------------------',
  "#{Rails.env}環境@#{`hostname`.chomp}",
  'マスキングを開始してよろしいですか？(yes/no) > ',
  '--------------------------------------',
  )
  ans = STDIN.gets until ans =~ /yes/ || ans =~ /no/

  if /yes/.match?(ans)
    puts '[INFO] マスキングを開始します.'

    # 引数で指定されたパスワードを設定する。引数を指定しない場合、パスワードは102310。
    password_digest = BCrypt::Password.create(args[:password].presence || 102310)

    ActiveRecord::Base.transaction do
    
      CashbackHistory.unscoped.update_all("
        notes = CONCAT('note', id)
      ")

      ChangeProductApply.unscoped.update_all("
        memo = CONCAT('memo', id)
      ")

      Contractor.unscoped.update_all("
        tax_id                           = LPAD(id, 13, '0'),
        notes                            = CONCAT('notes_', id),
        th_company_name                  = CONCAT('th_company_name_', id),
        en_company_name                  = CONCAT('en_company_name_', id),
        address                          = CONCAT('address_', id),
        phone_number                     = LPAD(id, 11, '0'),
        registration_no                  = LPAD(id, 13, '0'),
        establish_year                   = LPAD(id, 4, '0'),
        employee_count                   = LPAD(id, 6, '0'),
        th_owner_name                    = CONCAT('th_owner_name_', id),
        en_owner_name                    = CONCAT('en_owner_name_', id),
        owner_address                    = CONCAT('owner_address_', id),
        owner_birth_ymd                  = LPAD(id, 8, '0'),
        owner_personal_id                = LPAD(id, 13, '0'),
        owner_email                      = CONCAT(id, '@email.com'),
        owner_mobile_number              = LPAD(id, 11, '0'),
        owner_line_id                    = CONCAT('line_id_', id),
        authorized_person_name           = CONCAT('authorized_person_name_', id),
        authorized_person_title_division = CONCAT('a_title_division_', id),
        authorized_person_personal_id    = LPAD(id, 13, '0'),
        authorized_person_email          = CONCAT(id, '@email.com'),
        authorized_person_mobile_number  = LPAD(id, 11, '0'),
        authorized_person_line_id        = CONCAT('line_id_', id),
        contact_person_name              = CONCAT('contact_person_name_', id),
        contact_person_title_division    = CONCAT('c_title_division_', id),
        contact_person_personal_id       = LPAD(id, 13, '0'),
        contact_person_email             = CONCAT(id, '@email.com'),
        contact_person_mobile_number     = LPAD(id, 11, '0'),
        contact_person_line_id           = CONCAT('line_id_', id)
      ")

      ContractorBillingData.unscoped.update_all("
        th_company_name   = CONCAT('th_company_name_', id),
        address            = CONCAT('address_', id),
        tax_id            = LPAD('id', 13, '0'),
        installments_json = CONCAT('installments_json_', id)
      ")

      ContractorUser.unscoped.update_all("
        user_name       = LPAD(id, 13, '0'),
        full_name       = CONCAT('full_name_', id),
        mobile_number   = LPAD(id, 11, '0'),
        email           = CONCAT(id, '@email.com'),
        title_division  = CONCAT('title_division_', id),
        line_id         = CONCAT('line_id_', id),
        line_user_id    = CONCAT('line_user_id_', id),
        line_nonce      = CONCAT('line_nonce_', id),
        rudy_passcode   = LPAD(id, 6, '0'),
        password_digest = '#{password_digest}'
      ")

      Dealer.unscoped.update_all("
        tax_id       = LPAD(id, 13, '0'),
        dealer_code  = LPAD(id, 20, '0'),
        dealer_name  = CONCAT('dealer_name_', id),
        en_dealer_name  = CONCAT('en_dealer_name_', id),
        bank_account = CONCAT('bank_account_', id),
        address      = CONCAT('address_', id)
      ")

      DealerTypeSetting.unscoped.update_all("
        dealer_type_code = CONCAT('dealer_type_', id),
        sms_line_account = CONCAT('line_account_', id),
        sms_contact_info = CONCAT('sms_contact_info_', id)
      ")

      DealerUser.unscoped.update_all("
        user_name       = LPAD(id, 13, '0'),
        full_name       = CONCAT('full_name_', id),
        mobile_number   = LPAD(id, 11, '0'),
        email           = CONCAT(id, '@email.com'),
        password_digest = '#{password_digest}'
      ")

      Evidence.unscoped.update_all("
        comment = CONCAT('comment_', id)
      ")

      JvUser.unscoped.update_all("
        user_name       = LPAD(id, 13, '0'),
        full_name       = CONCAT('full_name_', id),
        mobile_number   = LPAD(id, 11, '0'),
        email           = CONCAT(id, '@email.com'),
        password_digest = '#{password_digest}'
      ")

      LineSpool.unscoped.update_all("
        send_to = CONCAT('send_to_', id),
        message_body = CONCAT('message_body_', id)
      ")

      MailSpool.unscoped.update_all("
        subject = CONCAT('subject_', id),
        mail_body = CONCAT('mail_body_', id)
      ")

      OneTimePasscode.unscoped.update_all("
        passcode = 'passcode'
      ")

      Order.unscoped.update_all("
        order_number = CONCAT('order_number_', id)
      ")

      PdpaVersion.unscoped.update_all("
        file_url = CONCAT('file_url_', id)
      ")

      Product.unscoped.update_all("
        product_key = LPAD(id, 4, '0'),
        product_name = CONCAT('product_name_', id),
        switch_sms_product_name = CONCAT('switch_sms_product_name_', id)
      ")

      ProjectDocument.unscoped.update_all("
        file_name = CONCAT('file_name_', id),
        comment = CONCAT('comment_', id)
      ")

      ProjectManagerUser.unscoped.update_all("
        user_name = LPAD(id, 13, '0'),
        full_name = CONCAT('full_name_', id),
        mobile_number = LPAD(id, 11, '0'),
        email = CONCAT(id, '@email.com'),
        password_digest = '#{password_digest}'
      ")

      ProjectManager.unscoped.update_all("
        tax_id = LPAD(id, 13, '0'),
        shop_id = LPAD(id, 10, '0'),
        project_manager_name = CONCAT('project_manager_name_', id)
      ")

      ProjectPhaseEvidence.unscoped.update_all("
        comment = CONCAT('comment_', id)
      ")

      ProjectPhaseSite.unscoped.update_all("
        site_code = LPAD(id, 15, '0'),
        site_name = CONCAT('site_name_', id) 
      ")

      ProjectPhase.unscoped.update_all("
        phase_number = LPAD(id, 20, '0'),
        phase_name = CONCAT('phase_name_', id)
      ")

      ProjectPhotoComment.unscoped.update_all("
        file_name = CONCAT('file_name_', id),
        comment = CONCAT('comment_', id)
      ")

      ProjectReceiveAmountHistory.unscoped.update_all("
        comment = CONCAT('comment_', id)
      ")

      Project.unscoped.update_all("
        project_code = CONCAT('project_code_', id),
        project_name = CONCAT('project_name_', id),
        project_owner = CONCAT('project_owner_', id),
        address = CONCAT('address_', id)
      ")

      ReceiveAmountDetail.unscoped.update_all("
        order_number = CONCAT('order_number_', id),
        dealer_name = CONCAT('dealer_name_', id),
        tax_id = LPAD(id, 13, '0'),
        th_company_name = CONCAT('th_company_name_', id),
        en_company_name = CONCAT('en_company_name_', id),
        site_code = LPAD(id, 15, '0'),
        site_name = CONCAT('site_name_', id),
        product_name = CONCAT('product_name_', id)
      ")

      ReceiveAmountHistory.unscoped.update_all("
        comment = CONCAT('comment_', id)
      ")

      RudyApiSetting.unscoped.update_all("
        user_name            = 'user_name',
        password             = 'password',
        bearer               = 'bearer',
        response_header_text = 'response_header_text',
        response_text        = 'response_text'
      ")

      ScoringComment.unscoped.update_all("
        comment = CONCAT('comment_', id)
      ")

      SendEmailAddress.unscoped.update_all("
        send_to = CONCAT(id, '@email.com')
      ")

      Site.unscoped.update_all("
        site_code = LPAD(id, 15, '0'),
        site_name = CONCAT('site_name_', id)
      ")

      SmsSpool.unscoped.update_all("
        send_to   = LPAD(id, 11, '0'),
        message_body = CONCAT('message_body_', id)
      ")

      puts '[INFO] マスキングが完了しました。'
    end

  else
    puts '[INFO] マスキングを実行しませんでした。'
  end

rescue => e
  print 'マスキングに失敗しました：'
  puts e
end