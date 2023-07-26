# == Schema Information
#
# Table name: projects
#
#  id                      :bigint(8)        not null, primary key
#  project_code            :string(255)      not null
#  project_type            :integer          not null
#  project_name            :string(255)      not null
#  project_manager_id      :bigint(8)        not null
#  project_value           :decimal(10, 2)
#  project_limit           :decimal(10, 2)   not null
#  delay_penalty_rate      :integer          not null
#  project_owner           :string(40)
#  start_ymd               :string(8)        not null
#  finish_ymd              :string(8)        not null
#  address                 :string(1000)
#  progress                :integer          default(0), not null
#  status                  :integer          default("opened"), not null
#  contract_registered_ymd :string(8)        not null
#  create_user_id          :bigint(8)        not null
#  update_user_id          :bigint(8)        not null
#  deleted                 :integer          default(0)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  operation_updated_at    :datetime
#  lock_version            :integer          default(0), not null
#

FactoryBot.define do
  factory :project do
    project_code { 'B0001' }
    project_type { 1 }
    project_name { 'project_name_1' }
    association :project_manager, factory: :project_manager
    project_value { 50000 }
    project_limit { 50000 }
    delay_penalty_rate { 18 }
    project_owner { 'project_owner_1' }
    start_ymd { '20211115' }
    finish_ymd { '20211215' }
    address { 'tokyo' }
    contract_registered_ymd { '20211120' }
    association :create_user, factory: :jv_user
    association :update_user, factory: :jv_user
  end
end
