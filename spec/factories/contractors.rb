# frozen_string_literal: true
# == Schema Information
#
# Table name: contractors
#
#  id                                       :bigint(8)        not null, primary key
#  tax_id                                   :string(15)       not null
#  contractor_type                          :integer          default("normal"), not null
#  main_dealer_id                           :integer
#  use_only_credit_limit                    :boolean          default(FALSE), not null
#  application_type                         :integer          not null
#  approval_status                          :integer          not null
#  application_number                       :string(20)
#  registered_at                            :datetime
#  register_user_id                         :integer
#  enable_rudy_confirm_payment              :boolean          default(TRUE)
#  pool_amount                              :decimal(10, 2)   default(0.0), not null
#  delay_penalty_rate                       :integer          default(18), not null
#  is_switch_unavailable                    :boolean          default(FALSE), not null
#  status                                   :integer          default("active"), not null
#  exemption_late_charge_count              :integer          default(0), not null
#  project_exemption_late_charge_count      :integer          default(0), not null
#  check_payment                            :boolean          default(FALSE), not null
#  stop_payment_sms                         :boolean          default(FALSE), not null
#  notes                                    :text(65535)
#  notes_updated_at                         :datetime
#  notes_update_user_id                     :integer
#  doc_company_registration                 :boolean          default(FALSE), not null
#  doc_vat_registration                     :boolean          default(FALSE), not null
#  doc_owner_id_card                        :boolean          default(FALSE), not null
#  doc_authorized_user_id_card              :boolean          default(FALSE), not null
#  doc_bank_statement                       :boolean          default(FALSE), not null
#  doc_tax_report                           :boolean          default(FALSE), not null
#  th_company_name                          :string(100)
#  en_company_name                          :string(100)
#  address                                  :string(200)
#  phone_number                             :string(20)
#  registration_no                          :string(30)
#  establish_year                           :string(4)
#  establish_month                          :string(2)
#  employee_count                           :string(6)
#  capital_fund_mil                         :string(20)
#  shareholders_equity                      :decimal(20, 2)
#  recent_revenue                           :decimal(20, 2)
#  short_term_loan                          :decimal(20, 2)
#  long_term_loan                           :decimal(20, 2)
#  recent_profit                            :decimal(20, 2)
#  apply_from                               :string(255)
#  th_owner_name                            :string(40)
#  en_owner_name                            :string(40)
#  owner_address                            :string(200)
#  owner_sex                                :integer
#  owner_birth_ymd                          :string(8)
#  owner_personal_id                        :string(20)
#  owner_email                              :string(200)
#  owner_mobile_number                      :string(15)
#  owner_line_id                            :string(20)
#  authorized_person_same_as_owner          :boolean          default(FALSE), not null
#  authorized_person_name                   :string(40)
#  authorized_person_title_division         :string(40)
#  authorized_person_personal_id            :string(20)
#  authorized_person_email                  :string(200)
#  authorized_person_mobile_number          :string(15)
#  authorized_person_line_id                :string(20)
#  contact_person_same_as_owner             :boolean          default(FALSE), not null
#  contact_person_same_as_authorized_person :boolean          default(FALSE), not null
#  contact_person_name                      :string(40)
#  contact_person_title_division            :string(40)
#  contact_person_personal_id               :string(20)
#  contact_person_email                     :string(200)
#  contact_person_mobile_number             :string(15)
#  contact_person_line_id                   :string(20)
#  approved_at                              :datetime
#  approval_user_id                         :integer
#  update_user_id                           :integer
#  online_apply_token                       :string(30)
#  deleted                                  :integer          default(0), not null
#  rejected_at                              :datetime
#  reject_user_id                           :integer
#  created_at                               :datetime         not null
#  create_user_id                           :integer
#  updated_at                               :datetime         not null
#  operation_updated_at                     :datetime
#  qr_code_updated_at                       :datetime
#  lock_version                             :integer          default(0)
#

FactoryBot.define do
  factory :contractor do
    trait :sub_dealer do
      contractor_type { :sub_dealer }
    end

    trait :pre_registration do
      approval_status { :pre_registration }
    end

    trait :processing do
      approval_status { :processing }
    end

    trait :qualified do
      approval_status { :qualified }
    end

    transient do
      create_dealer_limit { nil }
    end

    after(:create) do |contractor, evaluator|
      if evaluator.create_dealer_limit.present?
        eligibility = FactoryBot.create(:eligibility, contractor: contractor)
        FactoryBot.create(:dealer_limit, eligibility: eligibility, dealer: evaluator.create_dealer_limit)
      end
    end

    sequence(:tax_id) { |i| "1#{format('%012d', i)}" }

    # association :main_dealer
    contractor_type { :normal }
    application_type { "applied_paper" }
    approval_status { "qualified" }
    sequence(:application_number) { |i| "OLA-20220101-#{format("%06d", i)}" }
    notes { "notes" }
    notes_updated_at { "2019-01-01 00:00" }
    notes_update_user { nil }

    doc_company_registration { true }
    doc_vat_registration { true }
    doc_owner_id_card { true }
    doc_authorized_user_id_card { true }
    doc_bank_statement { false }
    doc_tax_report { false }

    th_company_name { "th_company_name" }
    en_company_name { "en_company_name" }
    address { "address" }
    phone_number { "000111222" }
    registration_no { "1" }
    establish_year { "2000" }
    employee_count { "100" }
    capital_fund_mil { "100" }

    th_owner_name { "th_owner_name" }
    en_owner_name { "en_owner_name" }
    owner_address { "owner_address" }
    owner_sex { "male" }
    owner_birth_ymd { "19700101" }
    sequence(:owner_personal_id) { |i| "1#{format('%012d', i)}" }
    owner_email { "owner@example.com" }
    owner_mobile_number { "000111222" }
    owner_line_id { "owner_line_id" }

    authorized_person_same_as_owner { false }
    authorized_person_name { "authorized_person_name" }
    authorized_person_title_division { "authorized_person" }
    sequence(:authorized_person_personal_id) { |i| "2#{format('%012d', i)}" }
    authorized_person_email { "authorized@example.com" }
    authorized_person_mobile_number { "111222333" }
    authorized_person_line_id { "authorized_line_id" }

    contact_person_same_as_owner { false }
    contact_person_same_as_authorized_person { false }
    contact_person_name { "contact_person_name" }
    contact_person_title_division { "contact_person" }
    sequence(:contact_person_personal_id) { |i| "3#{format('%012d', i)}" }
    contact_person_email { "contact@example.com" }
    contact_person_mobile_number { "333444555" }
    contact_person_line_id { "contact_line_id" }
  end
end
