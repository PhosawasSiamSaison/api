module MessageModule
  MASK_MESSAGE_BODIES = {
    # message_type => masked_message_body
    'send_one_time_passcode' => I18n.t('message.cannot_show_otp'),
    'online_apply_one_time_passcode' => I18n.t('message.cannot_show_otp'),
    'personal_id_confirmed' => I18n.t('message.cannot_show_otp'),
  }

  def mask_message_body
    MASK_MESSAGE_BODIES[message_type] || message_body
  end
end