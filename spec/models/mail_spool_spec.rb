# frozen_string_literal: true

# == Schema Information
#
# Table name: mail_spools
#
#  id                         :bigint(8)        not null, primary key
#  contractor_id              :bigint(8)
#  subject                    :string(255)
#  mail_body                  :text(65535)
#  mail_type                  :integer          not null
#  contractor_billing_data_id :bigint(8)
#  send_status                :integer          default("unsent"), not null
#  deleted                    :integer          default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  operation_updated_at       :datetime
#


require 'rails_helper'

RSpec.describe MailSpool, type: :model do
  describe '#email_addresses_str' do
    before do
      mail_spool = FactoryBot.create(:mail_spool)
      FactoryBot.create(:send_email_address, mail_spool: mail_spool, send_to: 'test1@test.com')
      FactoryBot.create(:send_email_address, mail_spool: mail_spool, send_to: 'test2@test.com')
    end

    it '宛先が正しいこと' do
      expect(MailSpool.first.email_addresses_str).to eq 'test1@test.com, test2@test.com'
    end
  end
end
