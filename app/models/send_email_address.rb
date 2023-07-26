# frozen_string_literal: true

# == Schema Information
#
# Table name: send_email_addresses
#
#  id                   :bigint(8)        not null, primary key
#  mail_spool_id        :bigint(8)        not null
#  contractor_user_id   :bigint(8)
#  send_to              :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#


class SendEmailAddress < ApplicationRecord
  belongs_to :mail_spool
  belongs_to :contractor_user, optional: true
end
