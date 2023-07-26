# == Schema Information
#
# Table name: contractor_billing_data
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)        not null
#  th_company_name      :string(255)
#  address              :string(255)
#  tax_id               :string(13)       not null
#  due_ymd              :string(8)        not null
#  credit_limit         :decimal(13, 2)
#  available_balance    :decimal(13, 2)
#  due_amount           :decimal(13, 2)
#  cut_off_ymd          :string(8)        not null
#  installments_json    :text(65535)
#  created_at           :datetime
#  updated_at           :datetime
#  operation_updated_at :datetime
#

FactoryBot.define do
  factory :contractor_billing_data do
    association :contractor
    th_company_name { "" }
    address { "" }
    tax_id { "" }
    due_ymd { "" }
    cut_off_ymd { "" }
    installments_json { "[]" }
  end
end
