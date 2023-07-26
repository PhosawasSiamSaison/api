class ApplicationRecord < ActiveRecord::Base
  include UnscopedAssociations, FormatterModule

  SUB_DEALER_LINE_ACCOUNT = '@saison_subdealer'

  # 追加時はDealerTypeSettingのレコードを追加する
  enum dealer_type: {
    cbm:          1,
    cpac:         2,
    global_house: 3,
    q_mix:        4,
    transformer:  5, # Supply Chain Finance
    solution:     6,
    b2b:          7,
    nam:          8,
    bigth:        9,
    permsin:     10,
    scgp:        11, # Boonthavorn
    rakmao:      12,
    cotto:       13,
    d_gov:       14, # 'governmentだとcontractor_typeのgovernmentと重複エラーが発生するため、d_govとする'
  }

  enum class_type: {
    s_class:         1,
    a_class:         2,
    b_class:         3,
    c_class:         4,
    d_class:         5,
    e_class:         6,
    f_class:         7,
    g_class:         8,
    h_class:         9,
    i_class:        10,
    reject_class:  101, # 'reject'だとActiveRecord::Relationで定義済みエラーが出るので'reject_class'にした。
    pending_class: 102,
  }

  enum send_status: { unsent: 1, sending: 2, done: 3, failed: 4 }

  enum message_type: {
    password_reset:                    1,
    register_user_on_approval:         2,
    personal_id_confirmed:             3,
    test_sending:                      4,
    reminder_two_days_before_due_date: 5,
    reminder_on_due_date:              6,
    inform_statement:                  7,
    over_due_next_day:                 8,
    send_one_time_passcode:            9,
    approval_change_product:          10,
    can_switch_7days_ago_sms:         11,
    new_site_information:             12,
    update_site_information:          13,
    create_cpac_order:                14,
    can_switch_3days_ago_sms:         15,
    create_contractor_user:           16,
    new_project_information:          17,
    update_project_information:       18,
    external_message_from_rudy:       19,
    external_message_from_ssa:        20,
    online_apply_one_time_passcode:   21,
    identity_verification_link:       22,
    reject_contractor:                23,
    pdpa_agree:                       24,
    login_to_rudy:                    25,
    online_apply_complete:            26,
    change_user_verify_mode_otp:      27,
    set_pf_site_limit:                28,
    receive_payment:                  29,

    # typeを追加したら locales の enum.application_record.message_typeに追加する
  }

  enum contractor_type: { normal: 1, sub_dealer: 2, individual: 3, government: 4 }

  # Available Setting
  enum category: { purchase: 1, switch: 2, cashback: 3 }

  self.abstract_class = true

  class << self
    # ページング
    def paginate(page, results, per_page)
      if results.is_a?(ActiveRecord::Relation)
        results.page(page).per(per_page)
      else
        Kaminari.paginate_array(results).page(page).per(per_page)
      end
    end

    def dealer_type_labels
      I18n.t("enum.application_record.dealer_type")
    end

    def labels(enum_name)
      enums_name = enum_name.pluralize

      types = send(enums_name).keys.map do |key|
        {
          code: key,
          label: new("#{enum_name}": key).send("#{enum_name}_label")[:label]
        }
      end

      # Dealer.dealer_typesの場合は CBM系の判定を追加する
      if to_s == 'Dealer' && enum_name == 'dealer_type'
        types.each do |type|
          type[:is_cbm_group] = Dealer.new(dealer_type: type[:code]).cbm_group?

          type
        end
      end

      types
    end
  end

  # エラーのログを出力する
  def error_messages
    logger.info "Validation Error: #{errors.messages}"
    logger.info "Error Messages: #{errors.full_messages}"

    errors.full_messages
  end

  # enumのkeyをlocaleに定義したラベルに変換
  def enum_to_label(enum_name, class_name: nil)
    class_name = class_name.presence || self.class.name.underscore

    label = send(enum_name).present? ?
      I18n.t("enum.#{class_name}.#{enum_name}.#{send(enum_name)}") : nil

    {
      code: send(enum_name),
      label: label
    }
  end

  def message_type_label
    enum_to_label('message_type')
  end

  def dealer_type_setting
    DealerTypeSetting.find_by(dealer_type: dealer_type)
  end

  # Siteを持てる DealerTypeかの判定
  def site_dealer?
    cpac_group? || project_group?
  end

  # CBM系
  def cbm_group?
    dealer_type_setting.cbm_group?
  end

  # CPAC系
  def cpac_group?
    dealer_type_setting.cpac_group?
  end

  # Project系
  def project_group?
    dealer_type_setting.project_group?
  end
end
