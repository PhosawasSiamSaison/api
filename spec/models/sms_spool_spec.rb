# frozen_string_literal: true

# == Schema Information
#
# Table name: sms_spools
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  contractor_user_id   :integer
#  send_to              :string(255)      not null
#  message_body         :text(65535)
#  message_type         :integer          not null
#  send_status          :integer          default("unsent"), not null
#  sms_provider         :integer
#  deleted              :integer          default(0), not null
#  lock_version         :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#


require 'rails_helper'

RSpec.describe SmsSpool, type: :model do
  describe '#mask_message_body' do
    it 'otpのmessageがマスクされること' do

      # 全てのmessage_typeを検証
      ApplicationRecord.message_types.keys.each do |key|
        sms_spool = SmsSpool.new(send_to: 'hoge', message_body: 'no mask', message_type: key)

        # 対象のtypeを判定して分岐
        if %w(send_one_time_passcode online_apply_one_time_passcode personal_id_confirmed).include?(sms_spool.message_type)
          expect(sms_spool.mask_message_body).to eq I18n.t('message.cannot_show_otp')
        else
          expect(sms_spool.mask_message_body).to eq sms_spool.message_body
        end
      end
    end
  end
end
