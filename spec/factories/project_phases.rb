# == Schema Information
#
# Table name: project_phases
#
#  id                   :bigint(8)        not null, primary key
#  project_id           :bigint(8)        not null
#  phase_number         :integer          not null
#  phase_name           :string(255)      not null
#  phase_value          :decimal(10, 2)   not null
#  phase_limit          :decimal(10, 2)   default(0.0)
#  start_ymd            :string(8)        not null
#  finish_ymd           :string(8)        not null
#  due_ymd              :string(8)        not null
#  paid_up_ymd          :string(8)
#  status               :integer          default("not_opened_yet"), not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

FactoryBot.define do
  factory :project_phase do
    trait :opened do
      status { :opened }
    end

    association :project, factory: :project
    sequence(:phase_number) { |i| "#{i}" }
    sequence(:phase_name) { |i| "Phase #{i}" }
    phase_value { 5000 }
    phase_limit { 5000 }
    start_ymd { "20211115" }
    finish_ymd { "20211130" }
    due_ymd { "20211101" }
  end
end
