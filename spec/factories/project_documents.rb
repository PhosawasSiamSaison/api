# == Schema Information
#
# Table name: project_documents
#
#  id                   :bigint(8)        not null, primary key
#  project_id           :bigint(8)        not null
#  file_type            :integer          not null
#  ss_staff_only        :boolean          default(FALSE)
#  file_name            :string(100)      not null
#  comment              :text(65535)
#  create_user_id       :bigint(8)        not null
#  update_user_id       :bigint(8)        not null
#  deleted              :integer          default(0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operation_updated_at :datetime
#  lock_version         :integer          default(0), not null
#

FactoryBot.define do
  factory :project_document do
    association :project, factory: :project
    file_type { "right_transfer_agreement" }
    file_name { "test_file.png" }
    comment { "test comment" }
    association :create_user, factory: :jv_user
    association :update_user, factory: :jv_user
  end
end
