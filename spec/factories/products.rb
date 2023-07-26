# frozen_string_literal: true
# == Schema Information
#
# Table name: products
#
#  id                      :bigint(8)        not null, primary key
#  product_key             :integer
#  product_name            :string(40)
#  switch_sms_product_name :string(255)
#  number_of_installments  :integer
#  sort_number             :integer
#  annual_interest_rate    :decimal(5, 2)
#  monthly_interest_rate   :decimal(5, 2)
#  deleted                 :integer          default(0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  operation_updated_at    :datetime
#  lock_version            :integer          default(0)
#

FactoryBot.define do
  factory :product1, class: Product do
    product_key { 1 }
    product_name { 'Product 1' }
    switch_sms_product_name { "product_1" }
    number_of_installments { 1 }
    annual_interest_rate { 0 }
    sort_number { 1 }
  end

  factory :product2, class: Product do
    product_key { 2 }
    product_name { 'Product 2' }
    switch_sms_product_name { "product_2" }
    number_of_installments { 3 }
    annual_interest_rate { 2.51 }
    sort_number { 3 }
  end

  factory :product3, class: Product do
    product_key { 3 }
    product_name { 'Product 3' }
    switch_sms_product_name { "product_3" }
    number_of_installments { 6 }
    annual_interest_rate { 4.42 }
    sort_number { 4 }
  end

  factory :product4, class: Product do
    product_key { 4 }
    product_name { 'Product 4' }
    switch_sms_product_name { "product_4" }
    number_of_installments { 1 }
    annual_interest_rate { 2.46 }
    sort_number { 2 }
  end

  factory :product5, class: Product do
    product_key { 5 }
    product_name { 'Product 5' }
    switch_sms_product_name { "product_5" }
    number_of_installments { 1 }
    annual_interest_rate { 0 }
    sort_number { 0 }
  end

  factory :product8, class: Product do
    product_key { 8 }
    product_name { 'Product 8' }
    switch_sms_product_name { "product_8" }
    number_of_installments { 1 }
    annual_interest_rate { 0.75 }
    sort_number { 0.75 }
  end
end
