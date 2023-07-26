# == Schema Information
#
# Table name: change_product_applies
#
#  id                   :bigint(8)        not null, primary key
#  contractor_id        :bigint(8)
#  due_ymd              :string(8)        not null
#  completed_at         :datetime
#  memo                 :string(500)
#  apply_user_id        :integer
#  register_user_id     :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0)
#

FactoryBot.define do
  factory :change_product_apply do
    trait :completed do
      completed_at { '2019-01-15 18:00:00' }
      memo { 'completed' }
      association :register_user, factory: :jv_user
    end

    association :contractor
    due_ymd { '20190115' }
    completed_at { nil }
    memo { nil }
    apply_user { nil }
    register_user { nil }
  end
end
