# == Schema Information
#
# Table name: project_phase_evidences
#
#  id                   :bigint(8)        not null, primary key
#  project_phase_id     :bigint(8)        not null
#  evidence_number      :string(10)       not null
#  comment              :text(65535)
#  checked_at           :datetime
#  checked_user_id      :bigint(8)
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

FactoryBot.define do
  factory :project_phase_evidence do
    association :project_phase, factory: :project_phase
    evidence_number { '0000000001' }
    comment { 'test_comment' }
  end
end
