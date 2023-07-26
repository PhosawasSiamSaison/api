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

FactoryBot.define do
  factory :mail_spool do
    mail_type { 1 }
    send_status { :unsent }
  end
end
