# frozen_string_literal: true
# == Schema Information
#
# Table name: dealer_type_settings
#
#  id                   :bigint(8)        not null, primary key
#  dealer_type          :integer          not null
#  dealer_type_code     :string(40)       not null
#  group_type           :integer          default(NULL), not null
#  switch_auto_approval :boolean          default(TRUE), not null
#  sms_line_account     :string(255)      not null
#  sms_contact_info     :string(150)      not null
#  sms_servcie_name     :string(150)      not null
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :dealer_type_setting do
    trait :cbm do
      dealer_type { :cbm }
      dealer_type_code { "cbm" }
      group_type { "cbm_group" }
      switch_auto_approval { false }
    end

    trait :cpac do
      dealer_type { :cpac }
      dealer_type_code { "cpac" }
      group_type { "cpac_group" }
      switch_auto_approval { true }

      sms_line_account { "@cpacsmilecredit" }
    end

    trait :global_house do
      dealer_type { :global_house }
      dealer_type_code { "global_house" }
      group_type { "cbm_group" }
      switch_auto_approval { false }
    end

    trait :q_mix do
      dealer_type { :q_mix }
      dealer_type_code { "q_mix" }
      group_type { "cpac_group" }
      switch_auto_approval { true }

      sms_line_account { "@qmixsaison" }
    end

    trait :transformer do
      dealer_type { :transformer }
      dealer_type_code { "transformer" }
      group_type { "cbm_group" }
      switch_auto_approval { false }
    end

    trait :solution do
      dealer_type { :solution }
      dealer_type_code { "cpac_sol" }
      group_type { "project_group" }
      switch_auto_approval { true }
    end

    trait :b2b do
      dealer_type { :b2b }
      dealer_type_code { "b2b" }
      group_type { "project_group" }
      switch_auto_approval { true }
    end

    trait :nam do
      dealer_type { :nam }
      dealer_type_code { "nam" }
      group_type { "cpac_group" }
      switch_auto_approval { false }
    end

    trait :bigth do
      dealer_type { :bigth }
      dealer_type_code { "bigth" }
      group_type { "cbm_group" }
      switch_auto_approval { true }
    end

    trait :permsin do
      dealer_type { :permsin }
      dealer_type_code { "permsin" }
      group_type { "cbm_group" }
      switch_auto_approval { true }
    end

    trait :scgp do
      dealer_type { :scgp }
      dealer_type_code { "scgp" }
      group_type { "cbm_group" }
      switch_auto_approval { true }
    end

    trait :rakmao do
      dealer_type { :rakmao }
      dealer_type_code { "rakmao" }
      group_type { "cbm_group" }
      switch_auto_approval { true }
    end

    trait :cotto do
      dealer_type { :cotto }
      dealer_type_code { "cotto" }
      group_type { "cbm_group" }
      switch_auto_approval { true }
    end

    trait :d_gov do
      dealer_type { :d_gov }
      dealer_type_code { "d_gov" }
      group_type { "project_group" }
      switch_auto_approval { true }
    end

    dealer_type { :cbm }
    dealer_type_code { "cbm" }
    sms_line_account { "@siamsaison" }
    sms_contact_info { "" }
    sms_servcie_name { "" }
  end
end
