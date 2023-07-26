# frozen_string_literal: true
# == Schema Information
#
# Table name: receive_amount_histories
#
#  id                    :bigint(8)        not null, primary key
#  contractor_id         :integer          not null
#  receive_ymd           :string(8)        not null
#  receive_amount        :decimal(10, 2)   not null
#  exemption_late_charge :decimal(10, 2)
#  comment               :text(65535)      not null
#  repayment_id          :string(32)
#  create_user_id        :integer
#  deleted               :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  operation_updated_at  :datetime
#  lock_version          :integer          default(0)
#

FactoryBot.define do
  factory :receive_amount_history do
    association :contractor
    receive_ymd { '20190115' }
    receive_amount { 100.0 }
    comment { 'test comment.' }
    association :create_user, factory: :jv_user
  end
end
