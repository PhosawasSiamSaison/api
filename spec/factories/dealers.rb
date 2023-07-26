# frozen_string_literal: true
# == Schema Information
#
# Table name: dealers
#
#  id                   :bigint(8)        not null, primary key
#  tax_id               :string(13)       not null
#  area_id              :integer          not null
#  dealer_type          :integer          not null
#  dealer_code          :string(20)       not null
#  for_normal_rate      :decimal(5, 2)    default(2.0), not null
#  for_government_rate  :decimal(5, 2)    default(1.75)
#  for_sub_dealer_rate  :decimal(5, 2)    default(1.5)
#  for_individual_rate  :decimal(5, 2)    default(1.5)
#  dealer_name          :string(50)
#  en_dealer_name       :string(50)
#  bank_account         :string(1000)
#  address              :string(1000)
#  interest_rate        :decimal(5, 2)
#  status               :integer          default("active"), not null
#  create_user_id       :integer
#  update_user_id       :integer
#  deleted              :integer          default(0), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :dealer, aliases: [:main_dealer] do
    sequence(:tax_id) { |i| format('%013d', i) }
    sequence(:dealer_code) { |i| "dealer_code#{i}" }
    sequence(:dealer_name) { |i| "dealer#{i}" }
    sequence(:en_dealer_name) { |i| "en_dealer#{i}" }
    dealer_type { 1 }
    status { 'active' }
    area_id { 1 }
    create_user { nil }
    update_user { nil }

    factory :cbm_dealer do
      dealer_type { :cbm }
    end

    factory :cpac_dealer do
      dealer_type { :cpac }
    end

    factory :global_house_dealer do
      dealer_type { :global_house }
    end

    factory :q_mix_dealer do
      dealer_type { :q_mix }
    end

    factory :b2b_dealer do
      dealer_type { :b2b }
    end

    factory :sol_dealer do
      dealer_type { :solution }
    end

    factory :permsin_dealer do
      dealer_type { :permsin }
    end
  end
end
