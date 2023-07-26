# == Schema Information
#
# Table name: project_phase_sites
#
#  id                   :bigint(8)        not null, primary key
#  project_phase_id     :bigint(8)        not null
#  contractor_id        :bigint(8)        not null
#  site_code            :string(255)      not null
#  site_name            :string(255)      not null
#  phase_limit          :decimal(10, 2)   not null
#  site_limit           :decimal(10, 2)   default(0.0), not null
#  paid_total_amount    :decimal(10, 2)   default(0.0)
#  refund_amount        :decimal(10, 2)   default(0.0)
#  status               :integer          default("opened"), not null
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

FactoryBot.define do
  factory :project_phase_site do
    association :project_phase, factory: :project_phase
    association :contractor, factory: :contractor
    sequence(:site_code) { |i| "ST#{i}" }
    sequence(:site_name) { |i| "Site#{i}" }
    phase_limit { 500.0 }
    site_limit { 500.0 }
    create_user { project.create_user }
    update_user { create_user }
  end
end
