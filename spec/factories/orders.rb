# frozen_string_literal: true
# == Schema Information
#
# Table name: orders
#
#  id                             :bigint(8)        not null, primary key
#  order_number                   :string(255)      not null
#  contractor_id                  :integer          not null
#  dealer_id                      :integer
#  second_dealer_id               :bigint(8)
#  site_id                        :integer
#  project_phase_site_id          :bigint(8)
#  order_type                     :string(30)
#  product_id                     :integer
#  bill_date                      :string(15)       default(""), not null
#  rescheduled_new_order_id       :integer
#  rescheduled_fee_order_id       :integer
#  rescheduled_user_id            :integer
#  rescheduled_at                 :datetime
#  fee_order                      :boolean          default(FALSE)
#  installment_count              :integer          not null
#  purchase_ymd                   :string(8)        not null
#  purchase_amount                :decimal(10, 2)   not null
#  amount_without_tax             :decimal(10, 2)
#  second_dealer_amount           :decimal(10, 2)
#  paid_up_ymd                    :string(8)
#  input_ymd                      :string(8)
#  input_ymd_updated_at           :datetime
#  change_product_status          :integer          default("unapply"), not null
#  is_applying_change_product     :boolean          default(FALSE), not null
#  applied_change_product_id      :integer
#  change_product_memo            :string(200)
#  change_product_before_due_ymd  :string(8)
#  change_product_applied_at      :datetime
#  product_changed_at             :datetime
#  product_changed_user_id        :integer
#  change_product_applied_user_id :integer
#  change_product_apply_id        :integer
#  region                         :string(50)
#  order_user_id                  :integer
#  canceled_at                    :datetime
#  canceled_user_id               :integer
#  rudy_purchase_ymd              :string(8)
#  uniq_check_flg                 :boolean          default(TRUE)
#  deleted                        :integer          default(0), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  operation_updated_at           :datetime
#  lock_version                   :integer          default(0)
#

FactoryBot.define do
  factory :order do
    trait :inputed_date do
      input_ymd { '20190101' }
      input_ymd_updated_at { '2019-01-01 00:00:00' }
    end

    trait :canceled do
      canceled_at { '2019-01-01 00:00:00' }
      association :canceled_user, factory: :jv_user
    end

    trait :paid do
      paid_up_ymd { '20190101' }
    end

    trait :fee_order do
      fee_order { true }
      rescheduled_at { Time.now }
    end

    trait :applied_change_product do
      change_product_status { :applied }
      is_applying_change_product { true }
      change_product_applied_at { Time.zone.now }
      applied_change_product_id { 2 }
      association :change_product_applied_user, factory: :contractor_user
    end

    trait :product_changed do
      is_applying_change_product { false }
      change_product_applied_at { Time.zone.now }
      applied_change_product_id { 2 }
      installment_count { 3 }
      association :change_product_applied_user, factory: :contractor_user
      change_product_before_due_ymd { '20190115' }
      product_changed_at { '2019-01-15 18:00:00' }
      association :product_changed_user, factory: :jv_user
    end

    trait :approved_change_product do
      product_changed
      change_product_status { :approval }
      change_product_memo { 'approval' }
    end

    trait :rejected_change_product do
      product_changed
      change_product_status { :rejected }
      change_product_memo { 'rejected' }
    end

    trait :project do
      association :project_phase_site
    end

    trait :cbm do
      site { nil }
      association :dealer, factory: :cbm_dealer
    end

    trait :cpac do
      association :site
      association :dealer, factory: :cpac_dealer
      order_user { nil }
    end

    trait :global_house do
      site { nil }
      association :dealer, factory: :global_house_dealer
    end

    trait :q_mix do
      association :site
      association :dealer, factory: :q_mix_dealer
      order_user { nil }
    end

    trait :product_key8 do
      product_id { 8 }
    end

    sequence(:order_number) { |i| format('%010d', i) }
    association :contractor
    association :dealer
    product_id { 1 }
    installment_count { product&.number_of_installments || 1 }
    purchase_ymd { '20190101' }
    purchase_amount { 1000000.0 }
    change_product_status { :unapply }
    is_applying_change_product { false }
    order_user { nil }
  end
end
