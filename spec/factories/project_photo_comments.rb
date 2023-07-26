# == Schema Information
#
# Table name: project_photo_comments
#
#  id                   :bigint(8)        not null, primary key
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
  factory :project_photo_comment do
    file_name { 'test.jpg' }
    comment { 'test_comment' }
    association :create_user, factory: :jv_user
    association :update_user, factory: :jv_user
  end
end
